import 'package:billetudo/features/goals/domain/entities/goal_momentum.dart';
import 'package:billetudo/features/goals/domain/services/goal_list_momentum_calculator.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../presentation/goals_presentation_fixtures.dart';

void main() {
  test('no goals carry momentum yields a signal-less aggregate', () {
    final result = GoalListMomentumCalculator.calculate([
      buildGoalWithProgress(),
    ]);

    expect(result.hasSignal, isFalse);
    expect(result.streakWeeks, 0);
    expect(result.hasMilestone, isFalse);
  });

  test('picks the best streak among the active goals, never a sum', () {
    final result = GoalListMomentumCalculator.calculate([
      buildGoalWithProgress(
        goal: buildGoal(id: 'a'),
        momentum: const GoalMomentum(streakWeeks: 2),
      ),
      buildGoalWithProgress(
        goal: buildGoal(id: 'b'),
        momentum: const GoalMomentum(streakWeeks: 6),
      ),
      buildGoalWithProgress(
        goal: buildGoal(id: 'c'),
        momentum: const GoalMomentum(streakWeeks: 1),
      ),
    ]);

    expect(result.streakWeeks, 6);
    expect(result.weeksSinceLastContribution, isNull);
  });

  test('when every streak is broken, surfaces the most recent activity', () {
    final result = GoalListMomentumCalculator.calculate([
      buildGoalWithProgress(
        goal: buildGoal(id: 'a'),
        momentum: const GoalMomentum(
          streakWeeks: 0,
          weeksSinceLastContribution: 5,
        ),
      ),
      buildGoalWithProgress(
        goal: buildGoal(id: 'b'),
        momentum: const GoalMomentum(
          streakWeeks: 0,
          weeksSinceLastContribution: 2,
        ),
      ),
    ]);

    expect(result.streakWeeks, 0);
    expect(result.weeksSinceLastContribution, 2);
    expect(result.hasSignal, isTrue);
  });

  test('picks the goal closest to its next milestone, by amount', () {
    final result = GoalListMomentumCalculator.calculate([
      buildGoalWithProgress(
        goal: buildGoal(id: 'far', name: 'Fondo de emergencia'),
        momentum: const GoalMomentum(
          streakWeeks: 0,
          nextMilestonePct: 25,
          amountToNextMilestoneMinor: 900000,
        ),
      ),
      buildGoalWithProgress(
        goal: buildGoal(id: 'near', name: 'Computador nuevo', currency: 'USD'),
        momentum: const GoalMomentum(
          streakWeeks: 0,
          nextMilestonePct: 50,
          amountToNextMilestoneMinor: 225000,
        ),
      ),
    ]);

    expect(result.nextMilestoneGoalName, 'Computador nuevo');
    expect(result.nextMilestonePct, 50);
    expect(result.amountToNextMilestoneMinor, 225000);
    expect(result.currency, 'USD');
    expect(result.hasMilestone, isTrue);
  });

  test('a fully-celebrated goal (no next milestone) is never picked', () {
    final result = GoalListMomentumCalculator.calculate([
      buildGoalWithProgress(
        goal: buildGoal(id: 'done'),
        momentum: const GoalMomentum(streakWeeks: 3),
      ),
    ]);

    expect(result.hasMilestone, isFalse);
    expect(result.nextMilestoneGoalName, isNull);
  });
}
