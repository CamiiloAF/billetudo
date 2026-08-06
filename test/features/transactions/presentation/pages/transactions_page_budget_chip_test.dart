import 'package:billetudo/features/transactions/domain/entities/budget_period_option.dart';
import 'package:billetudo/features/transactions/domain/entities/date_period_filter.dart';
import 'package:billetudo/features/transactions/domain/entities/transaction_filter.dart';
import 'package:billetudo/features/transactions/presentation/cubit/transactions_list_cubit.dart';
import 'package:billetudo/features/transactions/presentation/cubit/transactions_list_state.dart';
import 'package:billetudo/features/transactions/presentation/pages/transactions_page.dart';
import 'package:billetudo/features/transactions/presentation/widgets/filter_chip_pill.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../../categories/presentation/widgets/pump_widget.dart';

class MockTransactionsListCubit extends MockCubit<TransactionsListState>
    implements TransactionsListCubit {}

/// The 6th filter chip, "Presupuesto" (criterios 1/3): coexists with the
/// always-active Fecha chip, but — unlike it — has a genuine neutral state
/// when no budget is chosen, and switches to the active `primary-soft` look
/// with the selected budget's name once one is applied.
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

  FilterChipPill budgetChip(WidgetTester tester) => tester.widgetList<FilterChipPill>(
        find.byType(FilterChipPill),
      ).firstWhere((chip) => chip.label == 'Presupuesto' || chip.label == 'Comida');

  testWidgets('sin presupuesto aplicado, el chip queda neutro con el label '
      'genérico', (tester) async {
    await pump(
      tester,
      TransactionsListState(
        status: TransactionsListStatus.ready,
        filter: TransactionFilter(),
      ),
    );

    final chip = budgetChip(tester);
    expect(chip.label, 'Presupuesto');
    expect(chip.active, isFalse);
  });

  testWidgets('con un presupuesto aplicado, el chip queda activo con su '
      'nombre', (tester) async {
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

    final chip = budgetChip(tester);
    expect(chip.label, 'Comida');
    expect(chip.active, isTrue);
  });

  testWidgets('el chip Fecha se mantiene activo e independiente del chip '
      'Presupuesto', (tester) async {
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

    final dateChip = tester
        .widgetList<FilterChipPill>(find.byType(FilterChipPill))
        .firstWhere((chip) => chip.label == 'Este mes' || chip.label.contains('2026'));
    expect(dateChip.active, isTrue);
  });
}
