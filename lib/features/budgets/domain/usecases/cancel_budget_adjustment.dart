import 'package:injectable/injectable.dart';

import '../../../../core/error/result.dart';
import '../repositories/budget_repository.dart';

/// "Quitar ajuste": cancels the override pending for the window the stepper is
/// showing (`periodStart`), so that period keeps the budget's base amount
/// without any further action from the user.
@injectable
class CancelBudgetAdjustment {
  const CancelBudgetAdjustment(this._repository);

  final BudgetRepository _repository;

  FutureResult<Unit> call(
    String budgetId, {
    required DateTime periodStart,
  }) =>
      _repository.cancelBudgetAdjustment(budgetId, periodStart: periodStart);
}
