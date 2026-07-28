import 'package:injectable/injectable.dart';

import '../../../../core/error/result.dart';
import '../repositories/goal_repository.dart';

/// HU-10: soft delete via `deletedAt` (papelera/undo).
@injectable
class DeleteGoal {
  const DeleteGoal(this._repository);

  final GoalRepository _repository;

  FutureResult<Unit> call(String id) => _repository.deleteGoal(id);
}

/// HU-10: vaciar la papelera. A separate use case from [DeleteGoal] because
/// it is a **different, irreversible** operation — `tombstonedAt`, not
/// `deletedAt` — required because `Transactions.goalId` may still reference
/// this row.
@injectable
class PurgeGoal {
  const PurgeGoal(this._repository);

  final GoalRepository _repository;

  FutureResult<Unit> call(String id) => _repository.purgeGoal(id);
}
