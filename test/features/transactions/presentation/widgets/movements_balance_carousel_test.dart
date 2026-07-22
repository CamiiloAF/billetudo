import 'package:billetudo/core/preferences/balance_carousel_cubit.dart';
import 'package:billetudo/core/preferences/balance_carousel_preference_datasource.dart';
import 'package:billetudo/features/accounts/domain/entities/account.dart';
import 'package:billetudo/features/transactions/domain/entities/transaction_filter.dart';
import 'package:billetudo/features/transactions/domain/entities/transaction_with_details.dart';
import 'package:billetudo/features/transactions/presentation/cubit/transactions_list_state.dart';
import 'package:billetudo/features/transactions/presentation/pages/transactions_page.dart';
import 'package:billetudo/features/transactions/presentation/widgets/movements_balance_card.dart';
import 'package:billetudo/features/transactions/presentation/widgets/movements_balance_carousel.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../accounts/account_fixtures.dart';
import '../../../categories/presentation/widgets/pump_widget.dart';
import '../../transaction_fixtures.dart';

/// In-memory stand-in so the cubit under test never touches `shared_preferences`.
class _InMemoryCarouselPrefs implements BalanceCarouselPreferenceDatasource {
  _InMemoryCarouselPrefs({required bool collapsed}) : _collapsed = collapsed;

  bool _collapsed;

  @override
  Future<bool> readCollapsed() async => _collapsed;

  @override
  Future<void> writeCollapsed({required bool collapsed}) async =>
      _collapsed = collapsed;
}

void main() {
  final nequi = buildAccountWithBalance(
    account: buildAccount(id: 'a1', name: 'Nequi', type: AccountType.other),
    balanceMinor: 124000000,
  );
  final bancolombia = buildAccountWithBalance(
    account: buildAccount(id: 'a2', name: 'Bancolombia', type: AccountType.bank),
    balanceMinor: 300000000,
  );
  final visa = buildAccountWithBalance(
    account: buildCard(id: 'a3', name: 'Tarjeta Visa', creditLimitMinor: 300000000),
    balanceMinor: -68000000,
  );

  TransactionsListState stateWith({
    List<dynamic>? accounts,
    Set<String> accountIds = const <String>{},
  }) =>
      TransactionsListState(
        status: TransactionsListStatus.ready,
        accounts: (accounts ?? [nequi, bancolombia, visa]).cast(),
        filter: TransactionFilter(accountIds: accountIds),
      );

  Future<BalanceCarouselCubit> pumpCarousel(
    WidgetTester tester,
    TransactionsListState state, {
    bool collapsed = false,
    ValueChanged<String>? onOpenAccount,
  }) async {
    final cubit =
        BalanceCarouselCubit(_InMemoryCarouselPrefs(collapsed: collapsed));
    if (collapsed) {
      await cubit.collapse();
    }
    await tester.pumpAppWidget(
      BlocProvider<BalanceCarouselCubit>.value(
        value: cubit,
        child: MovementsBalanceCarousel(
          state: state,
          onOpenAccount: onOpenAccount ?? (_) {},
        ),
      ),
    );
    return cubit;
  }

  testWidgets('expanded shows one card per shown account with dots', (
    tester,
  ) async {
    await pumpCarousel(tester, stateWith());

    expect(find.byType(MovementsBalanceCard), findsWidgets);
    expect(find.text('Nequi'), findsOneWidget);
    // Three accounts -> three pagination dots.
    expect(find.byType(MovementsBalanceDots), findsOneWidget);
  });

  testWidgets('single account centres the card: no PageView, no dots', (
    tester,
  ) async {
    await pumpCarousel(tester, stateWith(accountIds: {'a2'}));

    expect(find.text('Bancolombia'), findsOneWidget);
    expect(find.text('Nequi'), findsNothing);
    expect(find.byType(MovementsBalanceDots), findsNothing);
    // Centred, not paged: a lone card is rendered directly, never in a
    // PageView with a phantom peek.
    expect(find.byType(PageView), findsNothing);
    expect(find.byType(MovementsBalanceCard), findsOneWidget);
  });

  testWidgets('tapping the single centred card opens that account', (
    tester,
  ) async {
    String? opened;
    await pumpCarousel(
      tester,
      stateWith(accountIds: {'a2'}),
      onOpenAccount: (id) => opened = id,
    );

    await tester.tap(find.byType(MovementsBalanceCard));
    await tester.pump();

    expect(opened, 'a2');
  });

  testWidgets('tapping a PageView card opens that account (not a swipe)', (
    tester,
  ) async {
    String? opened;
    await pumpCarousel(
      tester,
      stateWith(),
      onOpenAccount: (id) => opened = id,
    );

    // The first visible card is the first shown account (Nequi/a1).
    await tester.tap(find.byType(MovementsBalanceCard).first);
    await tester.pump();

    expect(opened, 'a1');
  });

  testWidgets('two or more accounts keep the PageView with peek and dots', (
    tester,
  ) async {
    await pumpCarousel(tester, stateWith(accountIds: {'a1', 'a2'}));

    expect(find.byType(PageView), findsOneWidget);
    expect(find.byType(MovementsBalanceDots), findsOneWidget);
  });

  testWidgets('credit card page renders debt and available-credit figures', (
    tester,
  ) async {
    await pumpCarousel(tester, stateWith(accountIds: {'a3'}));

    expect(find.byType(MovementsBalanceCardCredit), findsOneWidget);
    // Deuda 680.000 (abs of -680.000) and cupo disponible 2.320.000.
    expect(find.text(r'$680.000'), findsOneWidget);
    expect(find.text(r'$2.320.000'), findsOneWidget);
  });

  testWidgets('collapsed shows the compact bar with count and total', (
    tester,
  ) async {
    await pumpCarousel(tester, stateWith(), collapsed: true);

    expect(find.byType(MovementsBalanceCarouselCollapsed), findsOneWidget);
    expect(find.byType(MovementsBalanceCard), findsNothing);
    expect(find.text('3 cuentas'), findsOneWidget);
    // The visible "Saldo total" label was dropped so the amount always fits on
    // one line; the total figure itself is what the bar must still show.
    // 1.240.000 + 3.000.000 + (-680.000) = 3.560.000.
    expect(find.text(r'$3.560.000'), findsOneWidget);
  });

  testWidgets('tapping the collapse handle collapses the carousel', (
    tester,
  ) async {
    final cubit = await pumpCarousel(tester, stateWith());

    await tester.tap(find.byType(MovementsBalanceCollapseHandle));
    await tester.pumpAndSettle();

    expect(cubit.state.collapsed, isTrue);
    expect(find.byType(MovementsBalanceCarouselCollapsed), findsOneWidget);
  });

  testWidgets('tapping the collapsed bar re-expands the carousel', (
    tester,
  ) async {
    final cubit = await pumpCarousel(tester, stateWith(), collapsed: true);

    await tester.tap(find.byType(MovementsBalanceCarouselCollapsed));
    await tester.pumpAndSettle();

    expect(cubit.state.collapsed, isFalse);
    expect(find.byType(MovementsBalanceCard), findsWidgets);
  });

  testWidgets('renders nothing when there are no accounts', (tester) async {
    await pumpCarousel(tester, stateWith(accounts: const []));

    expect(find.byType(MovementsBalanceCard), findsNothing);
    expect(find.byType(MovementsBalanceCarouselCollapsed), findsNothing);
  });

  testWidgets('carousel is a scrollable header of the grouped list', (
    tester,
  ) async {
    final items = [
      TransactionWithDetails(
        transaction: buildTransaction(id: 'tx-1', amountMinor: 4500000),
        accountName: 'Efectivo',
        categoryName: 'Comida',
        categoryIcon: 'utensils',
      ),
    ];
    final state = TransactionsListState(
      status: TransactionsListStatus.ready,
      items: items,
      accounts: [nequi, bancolombia, visa],
      filter: TransactionFilter(),
    );
    final cubit =
        BalanceCarouselCubit(_InMemoryCarouselPrefs(collapsed: false));

    await tester.pumpAppWidget(
      BlocProvider<BalanceCarouselCubit>.value(
        value: cubit,
        child: TransactionsListView(
          state: state,
          onOpenTransaction: (_) {},
          onOpenAccount: (_) {},
        ),
      ),
    );

    // The carousel renders inside the vertically scrollable list, not pinned.
    expect(
      find.descendant(
        of: find.byType(Scrollable),
        matching: find.byType(MovementsBalanceCarousel),
      ),
      findsOneWidget,
    );
    expect(find.byType(MovementsBalanceCard), findsWidgets);
  });

  testWidgets(
    r'over-limit credit card shows debt and $0 available (floored)',
    (tester) async {
      // Limit 3.000.000, debt 3.500.000: the card is 500k over its limit, so
      // "Cupo disponible" is floored at $0, never a negative figure (HU-04).
      final overLimit = buildAccountWithBalance(
        account: buildCard(id: 'ol', name: 'Visa Sobrecupo', creditLimitMinor: 300000000),
        balanceMinor: -350000000,
      );
      await pumpCarousel(
        tester,
        TransactionsListState(
          status: TransactionsListStatus.ready,
          accounts: [overLimit],
          filter: TransactionFilter(accountIds: const {'ol'}),
        ),
      );

      expect(find.byType(MovementsBalanceCardCredit), findsOneWidget);
      // Deuda 3.500.000, cupo disponible $0.
      expect(find.text(r'$3.500.000'), findsOneWidget);
      expect(find.text(r'$0'), findsOneWidget);
    },
  );

  testWidgets(
    'in sort-by-amount (flat) mode the carousel is a scrollable header',
    (tester) async {
      final items = [
        TransactionWithDetails(
          transaction: buildTransaction(id: 'tx-1', amountMinor: 4500000),
          accountName: 'Efectivo',
          categoryName: 'Comida',
          categoryIcon: 'utensils',
        ),
      ];
      final state = TransactionsListState(
        status: TransactionsListStatus.ready,
        items: items,
        accounts: [nequi, bancolombia, visa],
        // Amount order flattens the list; the carousel must still ride at the
        // top of the same scrollable, not vanish or pin.
        filter: TransactionFilter(sortOrder: TransactionSortOrder.amountDesc),
      );
      final cubit =
          BalanceCarouselCubit(_InMemoryCarouselPrefs(collapsed: false));

      await tester.pumpAppWidget(
        BlocProvider<BalanceCarouselCubit>.value(
          value: cubit,
          child: TransactionsListView(
            state: state,
            onOpenTransaction: (_) {},
            onOpenAccount: (_) {},
          ),
        ),
      );

      expect(
        find.descendant(
          of: find.byType(Scrollable),
          matching: find.byType(MovementsBalanceCarousel),
        ),
        findsOneWidget,
      );
      expect(find.byType(MovementsBalanceCard), findsWidgets);
    },
  );

  testWidgets(
    'shrinking the account set below the active page does not crash and clamps '
    'the dots',
    (tester) async {
      // Open expanded on the third card (index 2) of three accounts.
      final cubit =
          BalanceCarouselCubit(_InMemoryCarouselPrefs(collapsed: false))
            ..pageChanged(2);
      await tester.pumpAppWidget(
        BlocProvider<BalanceCarouselCubit>.value(
          value: cubit,
          child: MovementsBalanceCarousel(
            state: stateWith(),
            onOpenAccount: (_) {},
          ),
        ),
      );
      expect(find.byType(MovementsBalanceDots), findsOneWidget);

      // The filter now narrows to two accounts: the widget rebuilds in place,
      // clamps the page from 2 down to the new last index and jumps there
      // without throwing a PageController range error.
      await tester.pumpAppWidget(
        BlocProvider<BalanceCarouselCubit>.value(
          value: cubit,
          child: MovementsBalanceCarousel(
            state: stateWith(accountIds: {'a1', 'a2'}),
            onOpenAccount: (_) {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      // Two accounts now -> two dots.
      final dots = tester.widget<MovementsBalanceDots>(
        find.byType(MovementsBalanceDots),
      );
      expect(dots.count, 2);
      expect(dots.active, lessThan(2));
    },
  );

  group('BalanceCarouselCubit', () {
    test('pageChanged records the active card and keeps collapse', () {
      final cubit =
          BalanceCarouselCubit(_InMemoryCarouselPrefs(collapsed: false))
            ..pageChanged(2);

      expect(cubit.state.currentPage, 2);
      expect(cubit.state.collapsed, isFalse);
    });

    test('collapse keeps the remembered page', () async {
      final cubit =
          BalanceCarouselCubit(_InMemoryCarouselPrefs(collapsed: false))
            ..pageChanged(1);

      await cubit.collapse();

      expect(cubit.state.collapsed, isTrue);
      expect(cubit.state.currentPage, 1);
    });

    test('load restores collapse without touching the page', () async {
      final cubit =
          BalanceCarouselCubit(_InMemoryCarouselPrefs(collapsed: true))
            ..pageChanged(2);

      await cubit.load();

      expect(cubit.state.collapsed, isTrue);
      expect(cubit.state.currentPage, 2);
    });
  });
}
