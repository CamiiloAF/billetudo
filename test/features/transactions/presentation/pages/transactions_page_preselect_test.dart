import 'package:billetudo/core/di/injection.dart';
import 'package:billetudo/core/preferences/balance_carousel_cubit.dart';
import 'package:billetudo/core/preferences/balance_carousel_preference_datasource.dart';
import 'package:billetudo/features/accounts/domain/usecases/has_any_active_account.dart';
import 'package:billetudo/features/accounts/domain/usecases/watch_active_accounts_count.dart';
import 'package:billetudo/features/transactions/domain/entities/transaction_filter.dart';
import 'package:billetudo/features/transactions/presentation/cubit/transactions_list_cubit.dart';
import 'package:billetudo/features/transactions/presentation/cubit/transactions_list_state.dart';
import 'package:billetudo/features/transactions/presentation/pages/transactions_page.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:mocktail/mocktail.dart';

import '../../../accounts/account_fixtures.dart';
import '../../../categories/presentation/widgets/pump_widget.dart';

class MockTransactionsListCubit extends MockCubit<TransactionsListState>
    implements TransactionsListCubit {}

class MockHasAnyActiveAccount extends Mock implements HasAnyActiveAccount {}

class MockWatchActiveAccountsCount extends Mock
    implements WatchActiveAccountsCount {}

class _FakeCarouselPrefs implements BalanceCarouselPreferenceDatasource {
  @override
  Future<bool> readCollapsed() async => false;

  @override
  Future<void> writeCollapsed({required bool collapsed}) async {}
}

/// The FAB's account preselection (Mejora #2): the new-movement form opens on
/// the account of the carousel's active card, read from the carousel cubit's
/// remembered page and clamped against the shown accounts. Covers all three
/// filter states plus the shrink-below-current-page clamp.
void main() {
  late MockTransactionsListCubit listCubit;

  final accounts = [
    buildAccountWithBalance(
      account: buildAccount(id: 'a1', name: 'Nequi'),
      balanceMinor: 100000,
    ),
    buildAccountWithBalance(
      account: buildAccount(id: 'a2', name: 'Bancolombia'),
      balanceMinor: 200000,
    ),
    buildAccountWithBalance(
      account: buildAccount(id: 'a3', name: 'Efectivo'),
      balanceMinor: 300000,
    ),
  ];

  setUp(() {
    listCubit = MockTransactionsListCubit();
    // The FAB now runs through the account gate (`15-gate-cuenta.md`)
    // before opening the form: an already-active account lets it through
    // straight away, matching every other test here that expects
    // `onAddTransaction` to fire.
    final hasAnyActiveAccount = MockHasAnyActiveAccount();
    when(hasAnyActiveAccount.call).thenAnswer((_) => Stream.value(true));
    getIt.registerFactory<HasAnyActiveAccount>(() => hasAnyActiveAccount);
    final watchActiveAccountsCount = MockWatchActiveAccountsCount();
    when(watchActiveAccountsCount.call).thenAnswer((_) => Stream.value(1));
    getIt.registerFactory<WatchActiveAccountsCount>(
      () => watchActiveAccountsCount,
    );
  });

  tearDown(getIt.reset);

  Future<String?> pumpAndTapFab(
    WidgetTester tester, {
    required TransactionsListState state,
    required int currentPage,
  }) async {
    when(() => listCubit.state).thenReturn(state);
    String? captured;
    var called = false;
    final carousel = BalanceCarouselCubit(_FakeCarouselPrefs())
      ..pageChanged(currentPage);

    await tester.pumpAppWidget(
      MultiBlocProvider(
        providers: [
          BlocProvider<TransactionsListCubit>.value(value: listCubit),
          BlocProvider<BalanceCarouselCubit>.value(value: carousel),
        ],
        child: TransactionsPage(
          onAddTransaction: (id) {
            called = true;
            captured = id;
          },
          onOpenTransaction: (_) async => null,
          onOpenAccount: (_) {},
        ),
      ),
    );

    await tester.tap(find.byIcon(LucideIcons.plus));
    // The gate check is async now (`showAccountGateIfNeeded`), so the FAB's
    // callback lands a couple of microtasks later than a single `pump()`.
    await tester.pumpAndSettle();
    expect(called, isTrue, reason: 'el FAB debe invocar onAddTransaction');
    return captured;
  }

  TransactionsListState readyWith({Set<String> accountIds = const {}}) =>
      TransactionsListState(
        status: TransactionsListStatus.ready,
        accounts: accounts,
        filter: TransactionFilter(accountIds: accountIds),
      );

  testWidgets('preselecciona la cuenta de la tarjeta activa (Todas)', (
    tester,
  ) async {
    final id = await pumpAndTapFab(
      tester,
      state: readyWith(),
      currentPage: 1,
    );

    // Página 1 de las tres mostradas -> Bancolombia.
    expect(id, 'a2');
  });

  testWidgets('con una sola cuenta filtrada preselecciona esa', (tester) async {
    final id = await pumpAndTapFab(
      tester,
      state: readyWith(accountIds: {'a3'}),
      currentPage: 0,
    );

    expect(id, 'a3');
  });

  testWidgets(
    'si el set encogió por debajo de la página activa, hace clamp al último',
    (tester) async {
      // La página recordada (5) quedó fuera de rango tras filtrar: se recorta
      // al último índice mostrado en vez de reventar.
      final id = await pumpAndTapFab(
        tester,
        state: readyWith(),
        currentPage: 5,
      );

      expect(id, 'a3');
    },
  );

  testWidgets('sin cuentas mostradas preselecciona null', (tester) async {
    final id = await pumpAndTapFab(
      tester,
      state: readyWith(accountIds: {'zzz'}),
      currentPage: 0,
    );

    expect(id, isNull);
  });
}
