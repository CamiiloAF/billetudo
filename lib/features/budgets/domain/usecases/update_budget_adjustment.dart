import 'package:injectable/injectable.dart';

import '../../../../core/error/result.dart';
import '../repositories/budget_repository.dart';

/// "Ajustar monto" (editar): changes the amount of the override already pending
/// for the window the stepper is showing (`periodStart`) without creating a
/// second one.
@injectable
class UpdateBudgetAdjustment {
  const UpdateBudgetAdjustment(this._repository);

  final BudgetRepository _repository;

  FutureResult<Unit> call(
    String budgetId, {
    required int newAmountMinor,
    required DateTime periodStart,
  }) =>
      _repository.updateBudgetAdjustment(
        budgetId,
        newAmountMinor: newAmountMinor,
        periodStart: periodStart,
      );
}
