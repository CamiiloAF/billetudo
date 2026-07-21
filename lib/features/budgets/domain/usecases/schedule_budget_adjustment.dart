import 'package:injectable/injectable.dart';

import '../../../../core/error/result.dart';
import '../repositories/budget_repository.dart';

/// "Ajustar monto — solo el próximo período" (crear): applies the fork of 3
/// parts for the first time on a recurring budget. Callers must have already
/// confirmed there is no pending fork (`GetPendingBudgetAdjustment` returned
/// `null`) — a second call on a budget that already has one must go through
/// `UpdateBudgetAdjustment` instead, never accumulate forks.
@injectable
class ScheduleBudgetAdjustment {
  const ScheduleBudgetAdjustment(this._repository);

  final BudgetRepository _repository;

  FutureResult<Unit> call(String budgetId, {required int newAmountMinor}) =>
      _repository.scheduleBudgetAdjustment(
        budgetId,
        newAmountMinor: newAmountMinor,
      );
}
