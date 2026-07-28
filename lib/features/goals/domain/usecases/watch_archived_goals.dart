import 'package:injectable/injectable.dart';

import '../../../../core/error/result.dart';
import '../entities/goal_with_progress.dart';
import '../repositories/goal_repository.dart';

/// HU-09: streams the archived goals (`Metas archivadas`), same shape as
/// [GoalWithProgress] the active list uses. Sorted by name so the list stays
/// stable regardless of archival order.
@injectable
class WatchArchivedGoals {
  const WatchArchivedGoals(this._repository);

  final GoalRepository _repository;

  Stream<Result<List<GoalWithProgress>>> call() =>
      _repository.watchArchivedGoals().map(
            (result) => result.map(
              (goals) => [...goals]
                ..sort((a, b) => a.goal.name.compareTo(b.goal.name)),
            ),
          );
}
