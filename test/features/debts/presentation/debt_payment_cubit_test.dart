import 'package:billetudo/core/error/result.dart';
import 'package:billetudo/core/preferences/debt_payment_toggle_preference_datasource.dart';
import 'package:billetudo/features/accounts/domain/entities/account_with_balance.dart';
import 'package:billetudo/features/accounts/domain/usecases/watch_accounts.dart';
import 'package:billetudo/features/debts/domain/entities/debt_cash_event.dart';
import 'package:billetudo/features/debts/domain/entities/debt_cash_event_draft.dart';
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

void main() {
  late MockRegisterDebtCashEvent registerCashEvent;
  late MockRegisterDebtLedgerEvent registerLedgerEvent;
  late MockWatchAccounts watchAccounts;
  late MockTogglePreference togglePreference;

  final accounts = [
    buildAccountWithBalance(
      account: buildAccount(id: 'a1', name: 'Bancolombia'),
      balanceMinor: 3450000,
    ),
  ];

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
    when(() => togglePreference.writeAddToAccount(
          debtId: any(named: 'debtId'),
          addToAccount: any(named: 'addToAccount'),
        )).thenAnswer((_) async {});
  });

  DebtPaymentCubit build() => DebtPaymentCubit(
        registerCashEvent,
        registerLedgerEvent,
        watchAccounts,
        togglePreference,
      );

  void withAccounts(List<AccountWithBalance> list, {required bool pref}) {
    when(watchAccounts.call)
        .thenAnswer((_) => Stream.value(Right(list)));
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
}
