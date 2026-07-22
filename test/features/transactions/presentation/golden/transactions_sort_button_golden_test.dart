import 'package:billetudo/features/transactions/domain/entities/transaction.dart';
import 'package:billetudo/features/transactions/domain/entities/transaction_filter.dart';
import 'package:billetudo/features/transactions/domain/entities/transaction_with_details.dart';
import 'package:billetudo/features/transactions/presentation/cubit/transactions_list_cubit.dart';
import 'package:billetudo/features/transactions/presentation/cubit/transactions_list_state.dart';
import 'package:billetudo/features/transactions/presentation/pages/transactions_page.dart';
import 'package:billetudo/features/transactions/presentation/widgets/transactions_sort_button.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../support/golden_helpers.dart';
import '../../transaction_fixtures.dart';

/// HU-06's Sort Button (`B3GGa`/`xAk6Y`) and its `Sort Menu` popover
/// (`xXWi0`/`dbTXb`), captured through the real `TransactionsPage` so the
/// popover's real anchoring (`PopupMenuButton`'s offset against the button)
/// and the button's active look both render exactly as a user would see them
/// — not a widget rebuilt in isolation.
class MockTransactionsListCubit extends MockCubit<TransactionsListState>
    implements TransactionsListCubit {}

void main() {
  late MockTransactionsListCubit cubit;

  setUpAll(() async {
    disableGoogleFontsRuntimeFetching();
    await loadMaterialIconsFont();
  });
  setUp(() => cubit = MockTransactionsListCubit());

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
        date: DateTime(2026, 7, 14),
      ),
      accountName: 'Bancolombia',
      categoryName: 'Salario',
      categoryIcon: 'briefcase',
      categoryColor: 'mint',
    ),
  ];

  Future<void> pumpPage(
    WidgetTester tester,
    TransactionsListState state, {
    required Brightness brightness,
  }) async {
    when(() => cubit.state).thenReturn(state);
    await pumpGolden(
      tester,
      BlocProvider<TransactionsListCubit>.value(
        value: cubit,
        child: TransactionsPage(
          onAddTransaction: (_) {},
          onOpenTransaction: (_) async => null,
          onOpenAccount: (_) {},
        ),
      ),
      brightness: brightness,
    );
  }

  for (final brightness in Brightness.values) {
    final suffix = brightness == Brightness.light ? 'light' : 'dark';

    // The 226px popover (`xXWi0`/`dbTXb`): two sections, "FECHA"/"MONTO",
    // four options with the untouched default (`dateDesc`) checked.
    testWidgets('sort menu popover open ($suffix)', (tester) async {
      await pumpPage(
        tester,
        TransactionsListState(
          status: TransactionsListStatus.ready,
          items: items,
          accounts: const [],
        ),
        brightness: brightness,
      );

      await tester.tap(find.byType(TransactionsSortButton));
      await tester.pumpAndSettle();

      await expectLater(
        find.byType(MaterialApp),
        matchesGoldenFile('goldens/transactions_sort_menu_popover_$suffix.png'),
      );
    });

    // The button's active look (`fill:$primary-soft`, `stroke:$primary`)
    // once the order leaves `dateDesc` — `dateAsc` on purpose, distinct from
    // `transactions_page_sorted_by_amount_*`, to prove the active style
    // applies to a date order too, while the list stays date-grouped (no
    // flat list, no "Ordenado por..." label — that only shows for amount
    // orders, see `TransactionsListView`).
    testWidgets('sort button active, date order ($suffix)', (tester) async {
      await pumpPage(
        tester,
        TransactionsListState(
          status: TransactionsListStatus.ready,
          items: items,
          accounts: const [],
          filter: TransactionFilter(sortOrder: TransactionSortOrder.dateAsc),
        ),
        brightness: brightness,
      );

      await expectLater(
        find.byType(TransactionsPage),
        matchesGoldenFile('goldens/transactions_sort_button_active_$suffix.png'),
      );
    });
  }
}
