import 'package:billetudo/core/preferences/balance_carousel_cubit.dart';
import 'package:billetudo/core/preferences/balance_carousel_preference_datasource.dart';
import 'package:billetudo/features/accounts/domain/entities/account.dart';
import 'package:billetudo/features/accounts/domain/entities/account_balance.dart';
import 'package:billetudo/features/accounts/domain/entities/account_with_balance.dart';
import 'package:billetudo/features/transactions/domain/entities/budget_period_option.dart';
import 'package:billetudo/features/transactions/domain/entities/date_period_filter.dart';
import 'package:billetudo/features/transactions/domain/entities/transaction.dart';
import 'package:billetudo/features/transactions/domain/entities/transaction_filter.dart';
import 'package:billetudo/features/transactions/domain/entities/transaction_with_details.dart';
import 'package:billetudo/features/transactions/presentation/cubit/transactions_list_cubit.dart';
import 'package:billetudo/features/transactions/presentation/cubit/transactions_list_state.dart';
import 'package:billetudo/features/transactions/presentation/pages/transactions_page.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../support/golden_helpers.dart';
import '../../transaction_fixtures.dart';

class MockTransactionsListCubit extends MockCubit<TransactionsListState>
    implements TransactionsListCubit {}

/// In-memory prefs so the balance carousel (Mejora #2) renders in its default
/// expanded state without touching `shared_preferences`.
class _FakeCarouselPrefs implements BalanceCarouselPreferenceDatasource {
  @override
  Future<bool> readCollapsed() async => false;

  @override
  Future<void> writeCollapsed({required bool collapsed}) async {}
}

/// Wraps [page] with the two cubits the transactions page reads.
Widget _withProviders(TransactionsListCubit cubit, Widget page) =>
    MultiBlocProvider(
      providers: [
        BlocProvider<TransactionsListCubit>.value(value: cubit),
        BlocProvider<BalanceCarouselCubit>(
          create: (_) => BalanceCarouselCubit(_FakeCarouselPrefs()),
        ),
      ],
      child: page,
    );

final DateTime _instant = DateTime(2026, 7, 15);
final int _instantMillis = _instant.millisecondsSinceEpoch;

AccountWithBalance _buildAccountWithBalance({
  String id = 'acc-1',
  String name = 'Efectivo',
  int balanceMinor = 450050,
}) {
  final account = Account(
    id: id,
    name: name,
    type: AccountType.cash,
    currency: 'COP',
    initialBalanceMinor: 0,
    archived: false,
    sortOrder: 0,
    createdAt: _instant,
    updatedAt: _instantMillis,
  );
  return AccountWithBalance(
    account: account,
    balance: AccountBalance.fromBalance(
        account: account, balanceMinor: balanceMinor),
  );
}

void main() {
  late MockTransactionsListCubit cubit;

  setUpAll(() async {
    disableGoogleFontsRuntimeFetching();
    await loadMaterialIconsFont();
  });
  setUp(() => cubit = MockTransactionsListCubit());

  Future<void> golden(
    WidgetTester tester,
    TransactionsListState state,
    String name, {
    required Brightness brightness,
    bool settle = true,
  }) async {
    when(() => cubit.state).thenReturn(state);
    await pumpGolden(
      tester,
      _withProviders(
        cubit,
        TransactionsPage(
          onAddTransaction: (_) {},
          onOpenTransaction: (_) async => null,
          onOpenAccount: (_) {},
        ),
      ),
      brightness: brightness,
      settle: settle,
    );
    await expectLater(
      find.byType(TransactionsPage),
      matchesGoldenFile('goldens/transactions_page_$name.png'),
    );
  }

  final items = [
    TransactionWithDetails(
      transaction: buildTransaction(
        id: 'tx-1',
        categoryId: 'cat-food',
        amountMinor: 4500000,
        date: DateTime(2026, 7, 15),
      ),
      accountName: 'Efectivo',
      categoryName: 'Comida',
      categoryIcon: 'utensils',
      categoryColor: 'coral',
    ),
    TransactionWithDetails(
      transaction: buildTransaction(
        id: 'tx-2',
        type: TransactionType.income,
        categoryId: 'cat-salary',
        amountMinor: 350000000,
        date: DateTime(2026, 7, 15),
      ),
      accountName: 'Bancolombia',
      categoryName: 'Salario',
      categoryIcon: 'briefcase',
      categoryColor: 'mint',
    ),
    TransactionWithDetails(
      transaction: buildTransaction(
        id: 'tx-3',
        type: TransactionType.transfer,
        transferAccountId: 'acc-2',
        amountMinor: 10000000,
        date: DateTime(2026, 7, 14),
      ),
      accountName: 'Efectivo',
      transferAccountName: 'Bancolombia',
      categoryIcon: 'arrow-left-right',
    ),
  ];

  // Regression fixture for the `maxLines: 2` + ellipsis fix in
  // `transaction_row.dart` (a long category name used to overflow instead of
  // wrapping/truncating).
  final longTitleItems = [
    TransactionWithDetails(
      transaction: buildTransaction(
        id: 'tx-long',
        categoryId: 'cat-long',
        amountMinor: 1250000,
        date: DateTime(2026, 7, 15),
        note: 'Con nota también, para completar la fila',
      ),
      accountName: 'Efectivo',
      categoryName:
          'Restaurantes y comida a domicilio del fin de semana con amigos',
      categoryIcon: 'utensils',
      categoryColor: 'coral',
    ),
    ...items,
  ];

  // Bugfix #11: with an exclusively-`expense` (or exclusively-`income`)
  // active type filter, `TransactionGroupHeader` shows the date group's
  // signed total instead of its "N movimientos" count. Two same-day,
  // same-currency items each, so the shown figure is visibly a sum (not
  // just one item's own amount).
  final expenseOnlyItems = [
    TransactionWithDetails(
      transaction: buildTransaction(
        id: 'tx-exp-1',
        categoryId: 'cat-food',
        amountMinor: 4500000,
        date: DateTime(2026, 7, 15),
      ),
      accountName: 'Efectivo',
      categoryName: 'Comida',
      categoryIcon: 'utensils',
      categoryColor: 'coral',
    ),
    TransactionWithDetails(
      transaction: buildTransaction(
        id: 'tx-exp-2',
        categoryId: 'cat-transport',
        amountMinor: 1200000,
        date: DateTime(2026, 7, 15),
      ),
      accountName: 'Efectivo',
      categoryName: 'Transporte',
      categoryIcon: 'car',
      categoryColor: 'blue',
    ),
  ];

  final incomeOnlyItems = [
    TransactionWithDetails(
      transaction: buildTransaction(
        id: 'tx-inc-1',
        type: TransactionType.income,
        categoryId: 'cat-salary',
        amountMinor: 350000000,
        date: DateTime(2026, 7, 15),
      ),
      accountName: 'Bancolombia',
      categoryName: 'Salario',
      categoryIcon: 'briefcase',
      categoryColor: 'mint',
    ),
    TransactionWithDetails(
      transaction: buildTransaction(
        id: 'tx-inc-2',
        type: TransactionType.income,
        categoryId: 'cat-freelance',
        amountMinor: 15000000,
        date: DateTime(2026, 7, 15),
      ),
      accountName: 'Bancolombia',
      categoryName: 'Freelance',
      categoryIcon: 'briefcase',
      categoryColor: 'mint',
    ),
  ];

  final accounts = <AccountWithBalance>[];

  // HU-06a's Account Chip has 3 states (`s8uIq`): a single account's own
  // name, a count for 2+, and "Todas" for no filter. These two accounts back
  // the `accountIds` filter used by the "N cuentas" golden below — matching
  // the ids `items` already reference (`acc-1`/`acc-2`).
  final accountsForChip = [
    _buildAccountWithBalance(),
    _buildAccountWithBalance(id: 'acc-2', name: 'Bancolombia'),
  ];

  // Same 3 transactions as `items`, but pre-sorted by absolute amount
  // descending — mirroring what `TransactionsListCubit`/the repository would
  // hand the page once `TransactionFilter.sortOrder` is `amountDesc` (HU-06).
  final itemsSortedByAmount = [items[1], items[0], items[2]];

  for (final brightness in Brightness.values) {
    final suffix = brightness == Brightness.light ? 'light' : 'dark';

    testWidgets('loading ($suffix)', (tester) async {
      await golden(
        tester,
        TransactionsListState(),
        'loading_$suffix',
        brightness: brightness,
        settle: false,
      );
    });

    testWidgets('empty, unfiltered ($suffix)', (tester) async {
      await golden(
        tester,
        TransactionsListState(status: TransactionsListStatus.ready),
        'empty_unfiltered_$suffix',
        brightness: brightness,
      );
    });

    testWidgets('empty, filtered ($suffix)', (tester) async {
      await golden(
        tester,
        TransactionsListState(
          status: TransactionsListStatus.ready,
          filter: TransactionFilter(searchText: 'xyz'),
        ),
        'empty_filtered_$suffix',
        brightness: brightness,
      );
    });

    testWidgets('with data: income, expense and transfer grouped ($suffix)',
        (tester) async {
      await golden(
        tester,
        TransactionsListState(
          status: TransactionsListStatus.ready,
          items: items,
          accounts: accounts,
        ),
        'with_data_$suffix',
        brightness: brightness,
      );
    });

    testWidgets(
        'with data: long category name wraps to 2 lines, not overflow '
        '($suffix)', (tester) async {
      await golden(
        tester,
        TransactionsListState(
          status: TransactionsListStatus.ready,
          items: longTitleItems,
          accounts: accounts,
        ),
        'with_data_long_title_$suffix',
        brightness: brightness,
      );
    });

    testWidgets('error ($suffix)', (tester) async {
      await golden(
        tester,
        TransactionsListState(status: TransactionsListStatus.failure),
        'error_$suffix',
        brightness: brightness,
      );
    });

    // HU-06a's Account Chip, "2+ selected" state (`XlXA8`/`idmDe`): a
    // generic `layers` leading icon and the "N cuentas" count label instead
    // of either account's own name.
    testWidgets('account chip: 2+ accounts selected ($suffix)', (tester) async {
      await golden(
        tester,
        TransactionsListState(
          status: TransactionsListStatus.ready,
          items: items,
          accounts: accountsForChip,
          filter: TransactionFilter(accountIds: const {'acc-1', 'acc-2'}),
        ),
        'account_chip_multi_$suffix',
        brightness: brightness,
      );
    });

    // HU-06a's Account Chip, "no filter" state (`s8uIq`/`H3bGO`): rendered as
    // the same active "Todas" pill, never as an unset 4th look — a `wallet`
    // leading icon and the "Todas" label.
    testWidgets('account chip: no filter, Todas ($suffix)', (tester) async {
      await golden(
        tester,
        TransactionsListState(
          status: TransactionsListStatus.ready,
          items: items,
          accounts: accountsForChip,
        ),
        'account_chip_all_$suffix',
        brightness: brightness,
      );
    });

    // The 6th filter chip, "Presupuesto" (criterios 1/3): coexists with the
    // always-active Fecha chip, and — unlike it — has a genuine neutral state
    // (`filter.hasBudgetPeriodFilter == false`) with the generic label and no
    // badge, mirroring the Cuenta chip's own "sin filtro" look.
    testWidgets('budget chip: no filter, neutral ($suffix)', (tester) async {
      await golden(
        tester,
        TransactionsListState(
          status: TransactionsListStatus.ready,
          items: items,
          accounts: accounts,
        ),
        'budget_chip_none_$suffix',
        brightness: brightness,
      );
    });

    // Same chip, active state: `primary-soft`/`primary` pill showing the
    // chosen budget's own name, resolved from `state.budgetOptions` the same
    // way the Cuenta chip resolves a single selected account's name.
    testWidgets('budget chip: budget selected, active ($suffix)',
        (tester) async {
      final budgetOption = BudgetPeriodOption(
        budgetId: 'budget-1',
        name: 'Comida',
        icon: 'utensils',
        start: DateTime(2026, 7),
        endExclusive: DateTime(2026, 8),
      );
      await golden(
        tester,
        TransactionsListState(
          status: TransactionsListStatus.ready,
          items: items,
          accounts: accounts,
          budgetOptions: [budgetOption],
          filter: TransactionFilter(
            budgetPeriod: DatePeriodFilter.budget(
              budgetId: 'budget-1',
              start: DateTime(2026, 7),
              endExclusive: DateTime(2026, 8),
            ),
          ),
        ),
        'budget_chip_selected_$suffix',
        brightness: brightness,
      );
    });

    // HU-06 sort by amount (`tigaH`/`Q8gSaB` in Pencil): once
    // `TransactionFilter.sortOrder` is an amount order, `TransactionsListView`
    // drops the date-grouped headers for a flat run of `Transaction Row`s
    // with the "Ordenado por monto" `Sort Label` above it, and
    // `TransactionsSortButton` switches to its active look
    // (`primary-soft`/`primary`) since the order left the default
    // `dateDesc`. See `transactions_sort_button_golden_test.dart` for the
    // popover itself and the active button on a *date* order.
    testWidgets('sorted by amount ($suffix)', (tester) async {
      await golden(
        tester,
        TransactionsListState(
          status: TransactionsListStatus.ready,
          items: itemsSortedByAmount,
          accounts: accounts,
          filter: TransactionFilter(
            sortOrder: TransactionSortOrder.amountDesc,
          ),
        ),
        'sorted_by_amount_$suffix',
        brightness: brightness,
      );
    });

    // Bugfix #11: exclusively-`expense` type filter -> the date group badge
    // shows the signed total ("-$57.000") instead of "2 movimientos".
    testWidgets('group total shown: expense-only filter ($suffix)',
        (tester) async {
      await golden(
        tester,
        TransactionsListState(
          status: TransactionsListStatus.ready,
          items: expenseOnlyItems,
          accounts: accounts,
          filter: TransactionFilter(
            types: const {TransactionType.expense},
          ),
        ),
        'group_total_expense_$suffix',
        brightness: brightness,
      );
    });

    // Bugfix #11: exclusively-`income` type filter -> the date group badge
    // shows the signed total ("+$3.650.000") instead of "2 movimientos".
    testWidgets('group total shown: income-only filter ($suffix)',
        (tester) async {
      await golden(
        tester,
        TransactionsListState(
          status: TransactionsListStatus.ready,
          items: incomeOnlyItems,
          accounts: accounts,
          filter: TransactionFilter(
            types: const {TransactionType.income},
          ),
        ),
        'group_total_income_$suffix',
        brightness: brightness,
      );
    });

    // HU-05's "Deshacer" snackbar (`lwvDp`): triggered by a real state
    // transition (previous `pendingUndoId` null -> non-null) through
    // `BlocConsumer.listenWhen`, not a static mocked state — a plain
    // `when(() => cubit.state)` never fires the listener.
    testWidgets('undo snackbar visible after delete ($suffix)', (tester) async {
      final baseState = TransactionsListState(
        status: TransactionsListStatus.ready,
        items: items,
        accounts: accounts,
      );
      final withUndo = baseState.copyWith(pendingUndoId: 'tx-1');
      whenListen(
        cubit,
        Stream<TransactionsListState>.value(withUndo),
        initialState: baseState,
      );

      await pumpGolden(
        tester,
        _withProviders(
          cubit,
          TransactionsPage(
            onAddTransaction: (_) {},
            onOpenTransaction: (_) async => null,
            onOpenAccount: (_) {},
          ),
        ),
        brightness: brightness,
      );
      await expectLater(
        find.byType(TransactionsPage),
        matchesGoldenFile(
            'goldens/transactions_page_undo_snackbar_$suffix.png'),
      );
    });
  }
}
