import 'package:injectable/injectable.dart';

import '../../../../core/error/result.dart';
import '../repositories/goal_repository.dart';

/// HU-09: desarchivar. Brings a paused goal back to the main list — a pure
/// visibility/business-state toggle — never touches `deletedAt` or the
/// movement history.
@injectable
class UnarchiveGoal {
  const UnarchiveGoal(this._repository);

  final GoalRepository _repository;

  FutureResult<Unit> call(String id) => _repository.unarchiveGoal(id);
}
