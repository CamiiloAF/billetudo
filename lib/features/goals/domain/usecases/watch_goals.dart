import 'package:injectable/injectable.dart';

import '../../../../core/error/result.dart';
import '../entities/goal_with_progress.dart';
import '../repositories/goal_repository.dart';

/// HU-11: streams the active goals list, ordered per the spec:
///  1. In-curso goals with a `targetDate`, nearest first.
///  2. In-curso goals with no `targetDate`.
///  3. Completed-but-not-archived goals, at the end.
/// (Archived and trashed goals never reach here — the repository already
/// excludes them.)
@injectable
class WatchGoals {
  const WatchGoals(this._repository);

  final GoalRepository _repository;

  Stream<Result<List<GoalWithProgress>>> call() =>
      _repository.watchGoals().map(
            (result) => result.map(sorted),
          );

  /// Exposed statically so the ordering rule is unit-testable without a
  /// stream/repository in the loop.
  static List<GoalWithProgress> sorted(List<GoalWithProgress> goals) {
    final withDate = <GoalWithProgress>[];
    final withoutDate = <GoalWithProgress>[];
    final completed = <GoalWithProgress>[];

    for (final goal in goals) {
      if (goal.goal.isCompleted) {
        completed.add(goal);
      } else if (goal.goal.targetDate != null) {
        withDate.add(goal);
      } else {
        withoutDate.add(goal);
      }
    }

    withDate.sort((a, b) => a.goal.targetDate!.compareTo(b.goal.targetDate!));

    return [...withDate, ...withoutDate, ...completed];
  }
}
