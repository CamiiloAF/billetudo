import 'package:billetudo/features/budgets/domain/entities/budget_period_window.dart';
import 'package:billetudo/features/budgets/domain/entities/budget_progress.dart';
import 'package:billetudo/features/budgets/domain/entities/budget_scope.dart';
import 'package:billetudo/features/budgets/domain/entities/budget_with_progress.dart';

import '../../budgets/domain/budget_fixtures.dart';

/// Shared builder for `HomeHeroStateResolver`/`WatchHasAnyBudget`/
/// `WatchHomeAiInsight` tests — a minimal current-period window so each test
/// only has to state the `progress` it actually cares about.
final BudgetPeriodWindow testHeroWindow = BudgetPeriodWindow(
  start: DateTime(2026, 7, 1),
  endExclusive: DateTime(2026, 8, 1),
  index: 0,
  status: BudgetWindowStatus.current,
  hasPrevious: false,
  hasNext: true,
);

BudgetWithProgress buildBudgetWithProgress({
  String id = 'b1',
  String currency = 'COP',
  required DateTime createdAt,
  BudgetProgress progress = const BudgetProgress(
    amountMinor: 600000,
    spentMinor: 300000,
    daysLeft: 12,
  ),
  BudgetPeriodWindow? window,
}) =>
    BudgetWithProgress(
      budget: buildBudget(
        id: id,
        currency: currency,
        startDate: DateTime(2026, 7, 1),
        createdAt: createdAt,
      ),
      scope: const BudgetScope.empty(),
      window: window ?? testHeroWindow,
      progress: progress,
    );
