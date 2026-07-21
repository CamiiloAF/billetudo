import 'package:injectable/injectable.dart';

import '../../../../core/error/result.dart';
import '../repositories/budget_repository.dart';

/// "Ajustar monto — solo el próximo período" (editar): changes the amount of
/// an already-pending fork without re-forking.
@injectable
class UpdateBudgetAdjustment {
  const UpdateBudgetAdjustment(this._repository);

  final BudgetRepository _repository;

  FutureResult<Unit> call(String budgetId, {required int newAmountMinor}) =>
      _repository.updateBudgetAdjustment(
        budgetId,
        newAmountMinor: newAmountMinor,
      );
}
