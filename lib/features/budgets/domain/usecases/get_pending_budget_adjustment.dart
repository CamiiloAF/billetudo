import 'package:injectable/injectable.dart';

import '../../../../core/error/result.dart';
import '../entities/pending_budget_adjustment.dart';
import '../repositories/budget_repository.dart';

/// "Ajustar monto — solo el próximo período": whether a budget already has a
/// pending fork, so the entry point's sheet knows to open in "crear" or
/// "editar/cancelar" mode.
@injectable
class GetPendingBudgetAdjustment {
  const GetPendingBudgetAdjustment(this._repository);

  final BudgetRepository _repository;

  FutureResult<PendingBudgetAdjustment?> call(String budgetId) =>
      _repository.getPendingAdjustment(budgetId);
}
