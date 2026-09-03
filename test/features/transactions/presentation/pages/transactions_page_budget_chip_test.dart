import 'package:billetudo/features/transactions/domain/entities/budget_period_option.dart';
import 'package:billetudo/features/transactions/domain/entities/date_period_filter.dart';
import 'package:billetudo/features/transactions/domain/entities/transaction_filter.dart';
import 'package:billetudo/features/transactions/presentation/cubit/transactions_list_cubit.dart';
import 'package:billetudo/features/transactions/presentation/cubit/transactions_list_state.dart';
import 'package:billetudo/features/transactions/presentation/pages/transactions_page.dart';
import 'package:billetudo/features/transactions/presentation/widgets/filters_button.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../../categories/presentation/widgets/pump_widget.dart';

class MockTransactionsListCubit extends MockCubit<TransactionsListState>
    implements TransactionsListCubit {}

/// GitHub issue #7: the "Filtros" button replaces the individual chips for
/// Presupuesto/Fecha/Tipo/Categoría/Etiqueta, with a numeric badge summing
/// every active dimension (`TransactionFilter.activeFilterCount`).
void main() {
  late MockTransactionsListCubit listCubit;

  final food = BudgetPeriodOption(
    budgetId: 'budget-1',
    name: 'Comida',
    start: DateTime(2026, 7),
    endExclusive: DateTime(2026, 8),
  );

  setUp(() => listCubit = MockTransactionsListCubit());

  Future<void> pump(WidgetTester tester, TransactionsListState state) async {
    when(() => listCubit.state).thenReturn(state);
    await tester.pumpAppWidget(
      BlocProvider<TransactionsListCubit>.value(
        value: listCubit,
        child: TransactionsPage(
          onAddTransaction: (_) {},
          onOpenTransaction: (_) async => null,
          onOpenAccount: (_) {},
        ),
      ),
    );
  }

  FiltersButton filtersButton(WidgetTester tester) =>
      tester.widget<FiltersButton>(find.byType(FiltersButton));

  testWidgets('sin filtros activos, el botón Filtros no muestra badge',
      (tester) async {
    await pump(
      tester,
      TransactionsListState(
        status: TransactionsListStatus.ready,
        filter: TransactionFilter(),
      ),
    );

    expect(filtersButton(tester).activeCount, 0);
  });

  testWidgets(
      'con un presupuesto aplicado, el botón Filtros muestra badge 1',
      (tester) async {
    await pump(
      tester,
      TransactionsListState(
        status: TransactionsListStatus.ready,
        budgetOptions: [food],
        filter: TransactionFilter(
          budgetPeriod: DatePeriodFilter.budget(
            budgetId: 'budget-1',
            start: DateTime(2026, 7),
            endExclusive: DateTime(2026, 8),
          ),
        ),
      ),
    );

    expect(filtersButton(tester).activeCount, 1);
  });

  testWidgets(
      'con presupuesto + categorías + etiqueta, el badge suma cada '
      'dimensión activa una sola vez', (tester) async {
    await pump(
      tester,
      TransactionsListState(
        status: TransactionsListStatus.ready,
        budgetOptions: [food],
        filter: TransactionFilter(
          budgetPeriod: DatePeriodFilter.budget(
            budgetId: 'budget-1',
            start: DateTime(2026, 7),
            endExclusive: DateTime(2026, 8),
          ),
          categoryIds: const {'cat-1', 'cat-2'},
          tagIds: const {'tag-1'},
        ),
      ),
    );

    expect(filtersButton(tester).activeCount, 3);
  });
}
