import 'package:injectable/injectable.dart';

import '../../../../core/error/result.dart';
import '../repositories/goal_repository.dart';

/// HU-09: archives a goal. A pure visibility/business-state toggle — never
/// touches `deletedAt` or the movement history.
@injectable
class ArchiveGoal {
  const ArchiveGoal(this._repository);

  final GoalRepository _repository;

  FutureResult<Unit> call(String id) => _repository.archiveGoal(id);
}
