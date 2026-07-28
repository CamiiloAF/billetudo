import 'package:injectable/injectable.dart';

import '../../../../core/error/result.dart';
import '../entities/goal_detail.dart';
import '../repositories/goal_repository.dart';

/// HU-05/HU-06/HU-07/HU-12/HU-15: streams one goal's detail. A thin
/// orchestration wrapper — the projection/momentum/coherence math already
/// lives in `GoalRepositoryImpl`, backed by the pure calculators in
/// `domain/services`.
@injectable
class WatchGoalDetail {
  const WatchGoalDetail(this._repository);

  final GoalRepository _repository;

  Stream<Result<GoalDetail>> call(String goalId) =>
      _repository.watchGoalDetail(goalId);
}
