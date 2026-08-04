import 'package:injectable/injectable.dart';

import '../../../../core/error/result.dart';
import '../../../budgets/domain/usecases/get_active_budgets.dart';
import '../entities/budget_period_option.dart';

/// The Movimientos "Presupuesto" filter chip's data source: wraps
/// [GetActiveBudgets] (HU-04, already excludes archived budgets) and maps
/// each `BudgetWithProgress` into the lighter [BudgetPeriodOption], so
/// Movimientos' presentation never imports Presupuestos domain entities
/// directly.
///
/// A live stream, not a one-shot read: reopening the filter sheet with a
/// budget already selected re-resolves its current window through this same
/// use case instead of reusing a window frozen at selection time (a budget's
/// "current period" can roll over between when the filter was applied and
/// when the sheet is reopened).
@injectable
class WatchBudgetPeriodOptions {
  const WatchBudgetPeriodOptions(this._getActiveBudgets);

  final GetActiveBudgets _getActiveBudgets;

  Stream<Result<List<BudgetPeriodOption>>> call() => _getActiveBudgets().map(
        (result) => result.map(
          (budgets) => budgets
              .map(
                (entry) => BudgetPeriodOption(
                  budgetId: entry.budget.id,
                  name: entry.budget.name,
                  icon: entry.budget.icon,
                  start: entry.window.start,
                  endExclusive: entry.window.endExclusive,
                ),
              )
              .toList(),
        ),
      );
}
