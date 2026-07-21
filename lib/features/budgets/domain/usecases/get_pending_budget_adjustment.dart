import 'package:injectable/injectable.dart';

import '../../../../core/error/result.dart';
import '../entities/pending_budget_adjustment.dart';
import '../repositories/budget_repository.dart';

/// "Ajustar monto": whether the window the stepper is showing (`periodStart`)
/// already has a pending override, so the banner shows and the sheet knows to
/// open in "crear" or "editar/cancelar" mode.
@injectable
class GetPendingBudgetAdjustment {
  const GetPendingBudgetAdjustment(this._repository);

  final BudgetRepository _repository;

  FutureResult<PendingBudgetAdjustment?> call(
    String budgetId, {
    required DateTime periodStart,
  }) =>
      _repository.getPendingAdjustment(budgetId, periodStart: periodStart);
}
