import 'package:clock/clock.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/error/result.dart';
import '../../../goals/domain/entities/goal_with_progress.dart';
import '../../../goals/domain/usecases/watch_goals.dart';
import '../entities/insight.dart';
import '../entities/insight_thresholds.dart';

/// "Alcanzaste tu meta de viaje", "Tu meta va en 75%" — the positive
/// reinforcement half of the notification center.
///
/// Reads `Goal.lastMilestonePct`, the threshold the goal has already crossed
/// and celebrated, so this never re-announces a milestone the app already
/// celebrated in-app, and a withdrawal-induced dip followed by a re-crossing
/// does not fire twice.
///
/// Two hard thresholds keep it from being noise: only 50/75/100 are
/// celebrated (25% is too early to be an achievement and frequent enough to
/// become clutter), and the crossing must be recent — an achievement from
/// last month is history, not news.
@injectable
class WatchGoalMilestoneInsights {
  const WatchGoalMilestoneInsights(this._watchGoals);

  final WatchGoals _watchGoals;

  Stream<Result<List<Insight>>> call() =>
      _watchGoals().map((result) => result.map(_insightsFrom));

  List<Insight> _insightsFrom(List<GoalWithProgress> goals) {
    final now = clock.now();
    final freshnessFloor = now.subtract(
      const Duration(days: InsightThresholds.goalMilestoneFreshnessDays),
    );

    final insights = <Insight>[];
    for (final entry in goals) {
      final goal = entry.goal;
      final milestone = goal.lastMilestonePct;
      if (!InsightThresholds.celebratedGoalPercents.contains(milestone)) {
        continue;
      }
      if (entry.savedMinor < InsightThresholds.minimumAmountMinor) {
        continue;
      }

      // When the milestone happened. `completedAt` is exact for a finished
      // goal; for an intermediate threshold the goal's own `updatedAt` is the
      // closest timestamp there is — crossing a threshold writes
      // `lastMilestonePct`, which is a write on the goal.
      final crossedAt = goal.completedAt ??
          DateTime.fromMillisecondsSinceEpoch(goal.updatedAt);
      if (crossedAt.isBefore(freshnessFloor)) {
        continue;
      }

      insights.add(
        Insight(
          id: 'goalMilestone:${goal.id}:$milestone',
          type: InsightType.goalMilestone,
          subject: goal.name,
          relevantOn: crossedAt,
          targetId: goal.id,
          amountMinor: entry.savedMinor,
          currency: goal.currency,
          progressPercent: milestone,
          targetAmountMinor: goal.targetMinor,
        ),
      );
    }

    // Most recent achievement first.
    insights.sort((a, b) => b.relevantOn.compareTo(a.relevantOn));
    return insights;
  }
}
