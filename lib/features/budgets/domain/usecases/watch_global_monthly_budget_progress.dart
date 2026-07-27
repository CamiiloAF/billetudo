import 'package:injectable/injectable.dart';

import '../../../../core/error/result.dart';
import '../entities/budget.dart';
import '../entities/budget_with_progress.dart';
import '../repositories/budget_repository.dart';

/// Home's hero progress bar (`docs/requirements/04-inicio.md`): the single
/// active budget, if any, that is both global (no account/category scope,
/// `BudgetScope.isGlobal`) and on the [BudgetPeriod.monthly] cadence. Home
/// only ever represents *this* exact profile — a global budget on another
/// period, or one scoped to accounts/categories, falls back to the "sin
/// presupuesto" hero state instead of being force-fit into it.
///
/// Nothing enforces a single global-monthly budget at creation time
/// (`CreateBudget` has no such uniqueness check), so when more than one
/// qualifies this picks the most recently **created** one — the budget the
/// user set up last is the one Home should reflect. Deterministic, not a
/// hard product rule.
@injectable
class WatchGlobalMonthlyBudgetProgress {
  const WatchGlobalMonthlyBudgetProgress(this._repository);

  final BudgetRepository _repository;

  Stream<Result<BudgetWithProgress?>> call() => _repository
      .watchActiveBudgets()
      .map((result) => result.map(_pickGlobalMonthly));

  BudgetWithProgress? _pickGlobalMonthly(List<BudgetWithProgress> budgets) {
    BudgetWithProgress? best;
    for (final entry in budgets) {
      final isEligible =
          entry.scope.isGlobal && entry.budget.period == BudgetPeriod.monthly;
      if (!isEligible) {
        continue;
      }
      if (best == null ||
          entry.budget.createdAt.isAfter(best.budget.createdAt)) {
        best = entry;
      }
    }
    return best;
  }
}
