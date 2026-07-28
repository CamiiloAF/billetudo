import 'package:injectable/injectable.dart';

import '../../../../core/error/result.dart';
import '../repositories/goal_quick_amounts_repository.dart';
import 'create_goal_quick_amount.dart';

/// Deletes a custom "aporte rápido" chip — the inline "x" on a personalized
/// chip. A real `DELETE`, instant, no confirmation sheet (the "Deshacer"
/// snackbar is the only undo, and it goes through
/// [CreateGoalQuickAmount] instead of restoring this row).
@injectable
class DeleteGoalQuickAmount {
  const DeleteGoalQuickAmount(this._repository);

  final GoalQuickAmountsRepository _repository;

  FutureResult<Unit> call(String id) => _repository.deleteQuickAmount(id);
}
