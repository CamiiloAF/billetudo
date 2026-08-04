import '../entities/goal_list_momentum.dart';
import '../entities/goal_with_progress.dart';

/// Pure domain aggregation of HU-15 for the goals **list** header: turns each
/// active goal's own `GoalMomentum` into one cross-goal, non-monetary signal.
/// Exposed as a static method (no dependencies to inject) so
/// `GoalsListState` can call it directly, the same precedent as
/// `WatchGoals.sorted`.
abstract final class GoalListMomentumCalculator {
  const GoalListMomentumCalculator._();

  static GoalListMomentum calculate(List<GoalWithProgress> goals) {
    var streakWeeks = 0;
    int? weeksSinceLastContribution;
    GoalWithProgress? nextMilestoneGoal;
    int? nextMilestoneAmount;

    for (final entry in goals) {
      final momentum = entry.momentum;
      if (momentum == null) {
        continue;
      }

      if (momentum.streakWeeks > streakWeeks) {
        streakWeeks = momentum.streakWeeks;
      }

      final weeksSince = momentum.weeksSinceLastContribution;
      if (weeksSince != null &&
          (weeksSinceLastContribution == null ||
              weeksSince < weeksSinceLastContribution)) {
        weeksSinceLastContribution = weeksSince;
      }

      final amount = momentum.amountToNextMilestoneMinor;
      if (amount == null) {
        continue;
      }
      if (nextMilestoneAmount == null || amount < nextMilestoneAmount) {
        nextMilestoneAmount = amount;
        nextMilestoneGoal = entry;
      }
    }

    // An active streak means momentum right now — the "since last
    // contribution" figure only makes sense to show when there isn't one.
    if (streakWeeks > 0) {
      weeksSinceLastContribution = null;
    }

    return GoalListMomentum(
      streakWeeks: streakWeeks,
      weeksSinceLastContribution: weeksSinceLastContribution,
      nextMilestoneGoalName: nextMilestoneGoal?.goal.name,
      nextMilestonePct: nextMilestoneGoal?.momentum?.nextMilestonePct,
      amountToNextMilestoneMinor: nextMilestoneAmount,
      currency: nextMilestoneGoal?.goal.currency,
    );
  }
}
