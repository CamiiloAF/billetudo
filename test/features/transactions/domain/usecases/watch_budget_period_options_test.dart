import 'package:billetudo/core/error/result.dart';
import 'package:billetudo/features/budgets/domain/entities/budget.dart';
import 'package:billetudo/features/budgets/domain/entities/budget_period_window.dart';
import 'package:billetudo/features/budgets/domain/entities/budget_progress.dart';
import 'package:billetudo/features/budgets/domain/entities/budget_scope.dart';
import 'package:billetudo/features/budgets/domain/entities/budget_with_progress.dart';
import 'package:billetudo/features/budgets/domain/repositories/budget_repository.dart';
import 'package:billetudo/features/budgets/domain/usecases/get_active_budgets.dart';
import 'package:billetudo/features/transactions/domain/entities/budget_period_option.dart';
import 'package:billetudo/features/transactions/domain/usecases/watch_budget_period_options.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockBudgetRepository extends Mock implements BudgetRepository {}

Budget _budget({
  required String id,
  required String name,
  String? icon,
}) =>
    Budget(
      id: id,
      name: name,
      icon: icon,
      amountMinor: 100000,
      currency: 'COP',
      period: BudgetPeriod.monthly,
      startDate: DateTime(2026, 1),
      recurring: true,
      rollover: false,
      createdAt: DateTime(2026, 1),
      updatedAt: DateTime(2026, 1).millisecondsSinceEpoch,
    );

BudgetWithProgress _withProgress({
  required String id,
  required String name,
  String? icon,
  required DateTime start,
  required DateTime endExclusive,
}) =>
    BudgetWithProgress(
      budget: _budget(id: id, name: name, icon: icon),
      scope: const BudgetScope.empty(),
      window: BudgetPeriodWindow(
        start: start,
        endExclusive: endExclusive,
        index: 0,
        status: BudgetWindowStatus.current,
        hasPrevious: false,
        hasNext: true,
      ),
      progress: const BudgetProgress(
        amountMinor: 100000,
        spentMinor: 20000,
        daysLeft: 15,
      ),
    );

void main() {
  test(
      'HU-04: mapea cada BudgetWithProgress activo a un BudgetPeriodOption '
      'ligero, con la ventana de su período actual', () async {
    final repository = _MockBudgetRepository();
    when(repository.watchActiveBudgets).thenAnswer(
      (_) => Stream<Result<List<BudgetWithProgress>>>.value(
        Right([
          _withProgress(
            id: 'budget-1',
            name: 'Comida',
            icon: 'utensils',
            start: DateTime(2026, 7),
            endExclusive: DateTime(2026, 8),
          ),
        ]),
      ),
    );
    final watchBudgetPeriodOptions =
        WatchBudgetPeriodOptions(GetActiveBudgets(repository));

    final result = await watchBudgetPeriodOptions().first;

    expect(
      result.getRight().toNullable(),
      [
        BudgetPeriodOption(
          budgetId: 'budget-1',
          name: 'Comida',
          icon: 'utensils',
          start: DateTime(2026, 7),
          endExclusive: DateTime(2026, 8),
        ),
      ],
    );
  });

  test('un presupuesto sin icono se mapea con icon null', () async {
    final repository = _MockBudgetRepository();
    when(repository.watchActiveBudgets).thenAnswer(
      (_) => Stream<Result<List<BudgetWithProgress>>>.value(
        Right([
          _withProgress(
            id: 'budget-2',
            name: 'Transporte',
            start: DateTime(2026, 7),
            endExclusive: DateTime(2026, 8),
          ),
        ]),
      ),
    );
    final watchBudgetPeriodOptions =
        WatchBudgetPeriodOptions(GetActiveBudgets(repository));

    final result = await watchBudgetPeriodOptions().first;

    expect(result.getRight().toNullable()!.single.icon, isNull);
  });

  test('depende de GetActiveBudgets: ya excluye los archivados', () async {
    final repository = _MockBudgetRepository();
    when(repository.watchActiveBudgets).thenAnswer(
      (_) =>
          Stream<Result<List<BudgetWithProgress>>>.value(const Right([])),
    );
    final watchBudgetPeriodOptions =
        WatchBudgetPeriodOptions(GetActiveBudgets(repository));

    final result = await watchBudgetPeriodOptions().first;

    expect(result.getRight().toNullable(), isEmpty);
  });

  test('propaga un failure del repositorio sin transformarlo', () async {
    final repository = _MockBudgetRepository();
    const failure = DatabaseFailure('boom');
    when(repository.watchActiveBudgets).thenAnswer(
      (_) => Stream<Result<List<BudgetWithProgress>>>.value(
        const Left(failure),
      ),
    );
    final watchBudgetPeriodOptions =
        WatchBudgetPeriodOptions(GetActiveBudgets(repository));

    final result = await watchBudgetPeriodOptions().first;

    expect(result.getLeft().toNullable(), failure);
  });
}
