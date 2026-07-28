import 'package:injectable/injectable.dart';

import '../../../../core/error/result.dart';
import '../repositories/goal_repository.dart';

/// HU-10: undo from the trash. Clears `deletedAt`.
@injectable
class RestoreGoal {
  const RestoreGoal(this._repository);

  final GoalRepository _repository;

  FutureResult<Unit> call(String id) => _repository.restoreGoal(id);
}
