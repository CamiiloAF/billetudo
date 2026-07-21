import 'package:injectable/injectable.dart';

import '../../../../core/error/result.dart';
import '../repositories/budget_repository.dart';

/// "Ajustar monto" (crear): writes the per-period override for the window the
/// stepper is showing (identified by `periodStart`) for the first time on a
/// recurring budget. Callers must have already confirmed that window has no
/// pending override (`GetPendingBudgetAdjustment` returned `null`) — a second
/// call on a window that already has one must go through `UpdateBudgetAdjustment`
/// instead, never accumulate overrides.
@injectable
class ScheduleBudgetAdjustment {
  const ScheduleBudgetAdjustment(this._repository);

  final BudgetRepository _repository;

  FutureResult<Unit> call(
    String budgetId, {
    required int newAmountMinor,
    required DateTime periodStart,
  }) =>
      _repository.scheduleBudgetAdjustment(
        budgetId,
        newAmountMinor: newAmountMinor,
        periodStart: periodStart,
      );
}
