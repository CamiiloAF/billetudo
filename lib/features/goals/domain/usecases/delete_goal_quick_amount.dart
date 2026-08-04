import 'package:injectable/injectable.dart';

import '../../../../core/error/result.dart';
import '../repositories/goal_quick_amounts_repository.dart';
import 'create_goal_quick_amount.dart';

/// Deletes any "aporte rápido" chip row — a default one seeded by
/// `CreateGoal` ($50.000/$100.000) or a personalized one created via
/// "+ Nueva"; both are plain `GoalQuickAmount` rows and this use case makes
/// no distinction between them. The inline "x" on every chip goes through
/// here. A real `DELETE`, instant, no confirmation sheet (the "Deshacer"
/// snackbar is the only undo, and it goes through
/// [CreateGoalQuickAmount] instead of restoring this row).
@injectable
class DeleteGoalQuickAmount {
  const DeleteGoalQuickAmount(this._repository);

  final GoalQuickAmountsRepository _repository;

  FutureResult<Unit> call(String id) => _repository.deleteQuickAmount(id);
}
