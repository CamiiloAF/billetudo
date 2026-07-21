import 'package:injectable/injectable.dart';

import '../../../../core/error/result.dart';
import '../repositories/budget_repository.dart';

/// "Quitar ajuste": cancels a pending fork, so the next cycle keeps the
/// budget's original amount without any further action from the user.
@injectable
class CancelBudgetAdjustment {
  const CancelBudgetAdjustment(this._repository);

  final BudgetRepository _repository;

  FutureResult<Unit> call(String budgetId) =>
      _repository.cancelBudgetAdjustment(budgetId);
}
