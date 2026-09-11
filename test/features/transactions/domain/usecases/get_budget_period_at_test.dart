import 'package:billetudo/core/error/result.dart';
import 'package:billetudo/features/budgets/domain/entities/budget_period_window.dart';
import 'package:billetudo/features/budgets/domain/usecases/get_budget_period_window_at.dart';
import 'package:billetudo/features/transactions/domain/usecases/get_budget_period_at.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockGetBudgetPeriodWindowAt extends Mock
    implements GetBudgetPeriodWindowAt {}

/// `GetBudgetPeriodAt`: Movimientos' own wrapper over Presupuestos'
/// `GetBudgetPeriodWindowAt`, mapping its `BudgetPeriodWindow` into a
/// `DatePeriodFilter` so presentation never imports Presupuestos domain
/// entities directly — same reasoning documented on `BudgetPeriodOption`.
void main() {
  late MockGetBudgetPeriodWindowAt getBudgetPeriodWindowAt;
  late GetBudgetPeriodAt usecase;

  setUp(() {
    getBudgetPeriodWindowAt = MockGetBudgetPeriodWindowAt();
    usecase = GetBudgetPeriodAt(getBudgetPeriodWindowAt);
  });

  test('maps the resolved window into a DatePeriodFilter.budget', () async {
    final window = BudgetPeriodWindow(
      start: DateTime(2026, 8, 25),
      endExclusive: DateTime(2026, 9, 25),
      index: 1,
      status: BudgetWindowStatus.current,
      hasPrevious: true,
      hasNext: false,
    );
    when(() => getBudgetPeriodWindowAt('budget-1', 1))
        .thenAnswer((_) async => Right(window));

    final result = await usecase(budgetId: 'budget-1', index: 1);

    final period = result.getRight().toNullable();
    expect(period, isNotNull);
    expect(period!.isBudgetPeriod, isTrue);
    expect(period.budgetId, 'budget-1');
    expect(period.start, DateTime(2026, 8, 25));
    expect(period.endExclusive, DateTime(2026, 9, 25));
    expect(period.index, 1);
    expect(period.hasPrevious, isTrue);
    expect(period.hasNext, isFalse);
  });

  test('forwards a failure unchanged', () async {
    const failure = NotFoundFailure('budget "budget-1" does not exist');
    when(() => getBudgetPeriodWindowAt('budget-1', 5))
        .thenAnswer((_) async => const Left(failure));

    final result = await usecase(budgetId: 'budget-1', index: 5);

    expect(result.getLeft().toNullable(), failure);
  });
}
