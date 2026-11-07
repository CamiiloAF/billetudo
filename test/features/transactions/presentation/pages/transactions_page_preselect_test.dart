import 'package:billetudo/core/di/injection.dart';
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

/// The FAB's account preselection: the new-movement form opens on the first
/// account the active filter shows ([TransactionsListState.displayedAccounts]
/// `.first`), and on none when the filter shows no account. Covers the
/// unfiltered list, a single-account filter, a multi-account filter (order
/// follows the account list, not the filter's set order) and the empty case.
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
  }) async {
    when(() => listCubit.state).thenReturn(state);
    String? captured;
    var called = false;

    await tester.pumpAppWidget(
      BlocProvider<TransactionsListCubit>.value(
        value: listCubit,
        child: TransactionsPage(
          onAddTransaction: (id) {
            called = true;
            captured = id;
          },
          onOpenTransaction: (_) async => null,
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

  testWidgets('sin filtro de cuenta preselecciona la primera cuenta (Todas)',
      (tester) async {
    final id = await pumpAndTapFab(tester, state: readyWith());

    expect(id, 'a1');
  });

  testWidgets('con una sola cuenta filtrada preselecciona esa', (tester) async {
    final id = await pumpAndTapFab(
      tester,
      state: readyWith(accountIds: {'a3'}),
    );

    expect(id, 'a3');
  });

  testWidgets(
    'con varias cuentas filtradas preselecciona la primera en el orden '
    'de la lista',
    (tester) async {
      // The filter set has no order; `displayedAccounts` preserves the order
      // of `accounts`, so `a1` wins even when `a3` is requested first.
      final id = await pumpAndTapFab(
        tester,
        state: readyWith(accountIds: {'a3', 'a1'}),
      );

      expect(id, 'a1');
    },
  );

  testWidgets('sin cuentas mostradas preselecciona null', (tester) async {
    final id = await pumpAndTapFab(
      tester,
      state: readyWith(accountIds: {'zzz'}),
    );

    expect(id, isNull);
  });
}
