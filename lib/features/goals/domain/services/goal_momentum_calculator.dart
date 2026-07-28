import 'package:injectable/injectable.dart';

import '../entities/goal.dart';
import '../entities/goal_contribution.dart';
import '../entities/goal_momentum.dart';
import 'goal_milestone_tracker.dart';

/// Pure domain service implementing HU-15: a streak of consecutive weeks
/// with at least one `contribution`, and the next milestone to cross. Never
/// a monetary total (that would sum across currencies of different goals).
@lazySingleton
class GoalMomentumCalculator {
  const GoalMomentumCalculator();

  GoalMomentum calculate({
    required Goal goal,
    required List<GoalContribution> contributions,
    required int savedMinor,
    DateTime? now,
  }) {
    final today = now ?? DateTime.now();
    final streakWeeks = _streakWeeks(contributions, today: today);

    int? nextMilestonePct;
    for (final threshold in GoalMilestoneTracker.thresholds) {
      if (threshold > goal.lastMilestonePct) {
        nextMilestonePct = threshold;
        break;
      }
    }

    final amountToNext = nextMilestonePct == null
        ? null
        : ((goal.targetMinor * nextMilestonePct) / 100).ceil() - savedMinor;

    return GoalMomentum(
      streakWeeks: streakWeeks,
      nextMilestonePct: nextMilestonePct,
      amountToNextMilestoneMinor:
          amountToNext == null ? null : (amountToNext < 0 ? 0 : amountToNext),
    );
  }

  /// Counts back from the week containing [today]: how many consecutive
  /// weeks (including the current, in-progress one only if it already has a
  /// contribution) have at least one `contribution` movement. Stops at the
  /// first gap — a broken streak is `0`, shown neutrally (HU-15).
  int _streakWeeks(List<GoalContribution> contributions, {required DateTime today}) {
    final weeksWithContribution = <int>{};
    final epoch = DateTime(2000);
    for (final contribution in contributions) {
      if (contribution.direction != GoalMovementDirection.contribution) {
        continue;
      }
      final weekIndex = contribution.date.difference(epoch).inDays ~/ 7;
      weeksWithContribution.add(weekIndex);
    }

    var currentWeek = today.difference(epoch).inDays ~/ 7;
    var streak = 0;
    while (weeksWithContribution.contains(currentWeek)) {
      streak++;
      currentWeek--;
    }
    return streak;
  }
}
