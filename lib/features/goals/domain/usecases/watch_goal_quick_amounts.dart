import 'package:injectable/injectable.dart';

import '../../../../core/error/result.dart';
import '../entities/goal_quick_amount.dart';
import '../repositories/goal_quick_amounts_repository.dart';

/// Streams the custom "aporte rápido" chips of a goal, feeding
/// `GoalQuickAmountRow` alongside the fixed $50.000/$100.000 pair.
@injectable
class WatchGoalQuickAmounts {
  const WatchGoalQuickAmounts(this._repository);

  final GoalQuickAmountsRepository _repository;

  Stream<Result<List<GoalQuickAmount>>> call(String goalId) =>
      _repository.watchQuickAmounts(goalId);
}
