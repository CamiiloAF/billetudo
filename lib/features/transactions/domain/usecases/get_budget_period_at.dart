import 'package:injectable/injectable.dart';

import '../../../../core/error/result.dart';
import '../../../budgets/domain/usecases/get_budget_period_window_at.dart';
import '../entities/date_period_filter.dart';

/// The Period Nav Bar's stepping primitive for a Presupuesto filter
/// (`design-system/billetudo/pages/transacciones.md` § "Period Nav Bar en la
/// pantalla principal"): wraps Presupuestos' [GetBudgetPeriodWindowAt] and
/// maps its `BudgetPeriodWindow` into a [DatePeriodFilter], so Movimientos'
/// presentation (`TransactionsListCubit`) never imports Presupuestos domain
/// entities directly — same reasoning as `WatchBudgetPeriodOptions`/
/// `BudgetPeriodOption`.
@injectable
class GetBudgetPeriodAt {
  const GetBudgetPeriodAt(this._getBudgetPeriodWindowAt);

  final GetBudgetPeriodWindowAt _getBudgetPeriodWindowAt;

  FutureResult<DatePeriodFilter> call({
    required String budgetId,
    required int index,
  }) async {
    final result = await _getBudgetPeriodWindowAt(budgetId, index);
    return result.map(
      (window) => DatePeriodFilter.budget(
        budgetId: budgetId,
        start: window.start,
        endExclusive: window.endExclusive,
        index: window.index,
        hasPrevious: window.hasPrevious,
        hasNext: window.hasNext,
      ),
    );
  }
}
