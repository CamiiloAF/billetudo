import 'package:billetudo/core/error/result.dart';
import 'package:billetudo/core/preferences/debt_payment_toggle_preference_datasource.dart';
import 'package:billetudo/features/accounts/domain/entities/account_with_balance.dart';
import 'package:billetudo/features/accounts/domain/usecases/watch_accounts.dart';
import 'package:billetudo/features/categories/domain/entities/category.dart';
import 'package:billetudo/features/categories/domain/usecases/get_category.dart';
import 'package:billetudo/features/debts/domain/entities/debt_cash_event.dart';
import 'package:billetudo/features/debts/domain/entities/debt_cash_event_draft.dart';
import 'package:billetudo/features/debts/domain/services/debt_category_seed.dart';
import 'package:billetudo/features/debts/domain/usecases/register_debt_cash_event.dart';
import 'package:billetudo/features/debts/domain/usecases/register_debt_ledger_event.dart';
import 'package:billetudo/features/debts/presentation/cubit/debt_payment_cubit.dart';
import 'package:billetudo/features/debts/presentation/cubit/debt_payment_state.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../accounts/account_fixtures.dart';
import 'debts_presentation_fixtures.dart';

class MockRegisterDebtCashEvent extends Mock implements RegisterDebtCashEvent {}

class MockRegisterDebtLedgerEvent extends Mock
    implements RegisterDebtLedgerEvent {}

class MockWatchAccounts extends Mock implements WatchAccounts {}

class MockTogglePreference extends Mock
    implements DebtPaymentTogglePreferenceDatasource {}

class MockGetCategory extends Mock implements GetCategory {}

void main() {
  late MockRegisterDebtCashEvent registerCashEvent;
  late MockRegisterDebtLedgerEvent registerLedgerEvent;
  late MockWatchAccounts watchAccounts;
  late MockTogglePreference togglePreference;
  late MockGetCategory getCategory;

  final accounts = [
    buildAccountWithBalance(
      account: buildAccount(id: 'a1', name: 'Bancolombia'),
      balanceMinor: 3450000,
    ),
  ];

  final seedCategory = Category(
    id: DebtCategorySeed.iOweCategoryId,
    name: 'Pago de préstamos',
    kind: CategoryKind.expense,
    sortOrder: 0,
    createdAt: DateTime(2024),
    updatedAt: 0,
    icon: 'wallet',
    color: 'mint',
  );

  setUpAll(() {
    registerFallbackValue(
      DebtCashEventDraft(
        debtId: 'd1',
        accountId: 'a1',
        amountMinor: 1,
        kind: DebtCashEventKind.payment,
        date: DateTime(2026),
      ),
    );
    registerFallbackValue(DebtCashEventKind.payment);
    registerFallbackValue(DateTime(2026));
  });

  setUp(() {
    registerCashEvent = MockRegisterDebtCashEvent();
    registerLedgerEvent = MockRegisterDebtLedgerEvent();
    watchAccounts = MockWatchAccounts();
    togglePreference = MockTogglePreference();
    getCategory = MockGetCategory();
    when(() => togglePreference.writeAddToAccount(
          debtId: any(named: 'debtId'),
          addToAccount: any(named: 'addToAccount'),
        )).thenAnswer((_) async {});
    when(() => getCategory(any())).thenAnswer((_) async => Right(seedCategory));
  });

  DebtPaymentCubit build() => DebtPaymentCubit(
        registerCashEvent,
        registerLedgerEvent,
        watchAccounts,
        togglePreference,
        getCategory,
      );

  void withAccounts(List<AccountWithBalance> list, {required bool pref}) {
    when(watchAccounts.call).thenAnswer((_) => Stream.value(Right(list)));
    when(() => togglePreference.readAddToAccount(any()))
        .thenAnswer((_) async => pref);
  }

  blocTest<DebtPaymentCubit, DebtPaymentState>(
    'start sin cuentas fuerza el registro solo-deuda (toggle No)',
    setUp: () => withAccounts(const [], pref: true),
    build: build,
    act: (cubit) => cubit.start(buildDebt()),
    skip: 1,
    expect: () => [
      isA<DebtPaymentState>()
          .having((s) => s.status, 'status', DebtPaymentStatus.ready)
          .having((s) => s.addToAccount, 'addToAccount', false)
          .having((s) => s.selectedAccountId, 'selectedAccountId', null),
    ],
  );

  blocTest<DebtPaymentCubit, DebtPaymentState>(
    'start con cuentas y preferencia Sí selecciona la primera cuenta',
    setUp: () => withAccounts(accounts, pref: true),
    build: build,
    act: (cubit) => cubit.start(buildDebt()),
    skip: 1,
    expect: () => [
      isA<DebtPaymentState>()
          .having((s) => s.status, 'status', DebtPaymentStatus.ready)
          .having((s) => s.addToAccount, 'addToAccount', true)
          .having((s) => s.selectedAccountId, 'selectedAccountId', 'a1'),
    ],
  );

  blocTest<DebtPaymentCubit, DebtPaymentState>(
    'submit en Sí registra un evento de caja y recuerda el toggle',
    setUp: () {
      withAccounts(accounts, pref: true);
      when(() => registerCashEvent.call(any()))
          .thenAnswer((_) async => const Right(unit));
    },
    build: build,
    act: (cubit) async {
      await cubit.start(buildDebt());
      cubit.amountChanged(150000);
      await cubit.submit();
    },
    skip: 3,
    expect: () => [
      isA<DebtPaymentState>()
          .having((s) => s.status, 'status', DebtPaymentStatus.saving),
      isA<DebtPaymentState>()
          .having((s) => s.status, 'status', DebtPaymentStatus.saved),
    ],
    verify: (_) {
      verify(() => registerCashEvent.call(any())).called(1);
      verifyNever(() => registerLedgerEvent.call(
            debtId: any(named: 'debtId'),
            kind: any(named: 'kind'),
            amountMinor: any(named: 'amountMinor'),
            date: any(named: 'date'),
            note: any(named: 'note'),
          ));
      verify(() => togglePreference.writeAddToAccount(
            debtId: 'd1',
            addToAccount: true,
          )).called(1);
    },
  );

  blocTest<DebtPaymentCubit, DebtPaymentState>(
    'submit en No registra un asiento solo-deuda, sin tocar caja',
    setUp: () {
      withAccounts(const [], pref: false);
      when(() => registerLedgerEvent.call(
            debtId: any(named: 'debtId'),
            kind: any(named: 'kind'),
            amountMinor: any(named: 'amountMinor'),
            date: any(named: 'date'),
            note: any(named: 'note'),
          )).thenAnswer((_) async => Right(buildEntry()));
    },
    build: build,
    act: (cubit) async {
      await cubit.start(buildDebt());
      cubit.amountChanged(80000);
      await cubit.submit();
    },
    skip: 3,
    expect: () => [
      isA<DebtPaymentState>()
          .having((s) => s.status, 'status', DebtPaymentStatus.saving),
      isA<DebtPaymentState>()
          .having((s) => s.status, 'status', DebtPaymentStatus.saved),
    ],
    verify: (_) {
      verify(() => registerLedgerEvent.call(
            debtId: 'd1',
            kind: DebtCashEventKind.payment,
            amountMinor: 80000,
            date: any(named: 'date'),
            note: any(named: 'note'),
          )).called(1);
      verifyNever(() => registerCashEvent.call(any()));
    },
  );

  blocTest<DebtPaymentCubit, DebtPaymentState>(
    'fix 7: start preselecciona la categoría semilla según la dirección '
    'de la deuda, con su ícono/color reales (fix: campo Categoría con '
    'ícono fijo)',
    setUp: () => withAccounts(accounts, pref: true),
    build: build,
    act: (cubit) => cubit.start(buildDebt()),
    skip: 1,
    expect: () => [
      isA<DebtPaymentState>()
          .having((s) => s.categoryId, 'categoryId', seedCategory.id)
          .having((s) => s.categoryName, 'categoryName', seedCategory.name)
          .having((s) => s.categoryIcon, 'categoryIcon', seedCategory.icon)
          .having((s) => s.categoryColor, 'categoryColor', seedCategory.color),
    ],
    verify: (_) {
      verify(
        () => getCategory(DebtCategorySeed.iOweCategoryId),
      ).called(1);
    },
  );

  blocTest<DebtPaymentCubit, DebtPaymentState>(
    'categorySelected propaga ícono/color de la categoría elegida en el '
    'picker, no solo id/name',
    setUp: () => withAccounts(accounts, pref: true),
    build: build,
    act: (cubit) async {
      await cubit.start(buildDebt());
      cubit.categorySelected(
        id: 'cat-transporte',
        name: 'Transporte',
        icon: 'bus',
        color: 'sky',
      );
    },
    skip: 2,
    expect: () => [
      isA<DebtPaymentState>()
          .having((s) => s.categoryId, 'categoryId', 'cat-transporte')
          .having((s) => s.categoryName, 'categoryName', 'Transporte')
          .having((s) => s.categoryIcon, 'categoryIcon', 'bus')
          .having((s) => s.categoryColor, 'categoryColor', 'sky'),
    ],
  );

  test(
    'fix 7: canSubmit exige categoría cuando addToAccount es true, '
    'incluso con cuenta y monto ya elegidos',
    () {
      final withoutCategory = DebtPaymentState(
        debt: buildDebt(),
        date: DateTime(2026),
        addToAccount: true,
        selectedAccountId: 'a1',
        amountMinor: 1000,
      );
      expect(withoutCategory.canSubmit, isFalse);

      final withCategory = withoutCategory.copyWith(
        categoryId: () => 'seed-debts',
      );
      expect(withCategory.canSubmit, isTrue);
    },
  );
}
