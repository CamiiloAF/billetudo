import 'package:injectable/injectable.dart';

import '../../../../core/error/result.dart';
import '../entities/budget_period_window.dart';
import '../repositories/budget_repository.dart';
import '../services/budget_period_calculator.dart';

/// The Period Nav Bar's stepping primitive (both Movimientos surfaces:
/// `design-system/billetudo/pages/transacciones.md` § "Period Nav Bar en la
/// pantalla principal"): resolves the window at `index` for `budgetId`,
/// without depending on whichever window happens to be "current" right now
/// (`GetActiveBudgets`/`BudgetPeriodOption` only ever expose that one).
///
/// Pure delegation to [BudgetPeriodCalculator] once the budget itself is
/// fetched — `BudgetPeriodCalculator.windowAt` is deterministic given the
/// budget and `now`, so this use case adds nothing but the repository read.
@injectable
class GetBudgetPeriodWindowAt {
  const GetBudgetPeriodWindowAt(this._repository);

  final BudgetRepository _repository;

  FutureResult<BudgetPeriodWindow> call(String budgetId, int index) async {
    final result = await _repository.getBudget(budgetId);
    return result.map(
      (budget) =>
          BudgetPeriodCalculator(budget).windowAt(index, DateTime.now()),
    );
  }
}
