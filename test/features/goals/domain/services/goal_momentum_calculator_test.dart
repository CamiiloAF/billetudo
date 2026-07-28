import 'package:billetudo/features/goals/domain/entities/goal.dart';
import 'package:billetudo/features/goals/domain/entities/goal_contribution.dart';
import 'package:billetudo/features/goals/domain/services/goal_momentum_calculator.dart';
import 'package:flutter_test/flutter_test.dart';

Goal _buildGoal({int targetMinor = 100000, int lastMilestonePct = 0}) => Goal(
      id: 'goal-1',
      name: 'Vacaciones',
      targetMinor: targetMinor,
      currency: 'COP',
      lastMilestonePct: lastMilestonePct,
      createdAt: DateTime(2026, 1, 1),
      updatedAt: DateTime(2026, 1, 1).millisecondsSinceEpoch,
    );

GoalContribution _contributionOn(
  DateTime date, {
  GoalMovementDirection direction = GoalMovementDirection.contribution,
}) =>
    GoalContribution(
      id: 'm-${date.toIso8601String()}',
      goalId: 'goal-1',
      amountMinor: 1000,
      direction: direction,
      date: date,
      createdAt: date,
      updatedAt: date.millisecondsSinceEpoch,
    );

void main() {
  const calculator = GoalMomentumCalculator();
  // A Thursday, so "this week" and "last week" are well inside 7-day windows
  // from the fixture dates below.
  final today = DateTime(2026, 7, 30);

  test('HU-15: never exposes a monetary total across goals — only a '
      'per-goal streak/next-milestone shape', () {
    final momentum = calculator.calculate(
      goal: _buildGoal(),
      contributions: const [],
      savedMinor: 0,
      now: today,
    );

    // The type itself has no aggregate-total field; asserting its declared
    // shape is what keeps this invariant from silently regressing.
    expect(momentum.props, [
      momentum.streakWeeks,
      momentum.nextMilestonePct,
      momentum.amountToNextMilestoneMinor,
    ]);
  });

  test('a contribution every week counts as a streak; a gap breaks it', () {
    final momentum = calculator.calculate(
      goal: _buildGoal(),
      contributions: [
        _contributionOn(today),
        _contributionOn(today.subtract(const Duration(days: 7))),
        _contributionOn(today.subtract(const Duration(days: 14))),
        // Gap here (no contribution 3 weeks ago) breaks the streak.
        _contributionOn(today.subtract(const Duration(days: 28))),
      ],
      savedMinor: 3000,
      now: today,
    );

    expect(momentum.streakWeeks, 3);
  });

  test('the current week with no contribution yet is a broken streak (0), '
      'shown neutrally, not as a failure', () {
    final momentum = calculator.calculate(
      goal: _buildGoal(),
      contributions: [
        _contributionOn(today.subtract(const Duration(days: 7))),
      ],
      savedMinor: 1000,
      now: today,
    );

    expect(momentum.streakWeeks, 0);
  });

  test('a withdrawal alone never counts toward the contribution streak', () {
    final momentum = calculator.calculate(
      goal: _buildGoal(),
      contributions: [
        _contributionOn(today, direction: GoalMovementDirection.withdrawal),
      ],
      savedMinor: 0,
      now: today,
    );

    expect(momentum.streakWeeks, 0);
  });

  test('reports the next uncrossed milestone and the amount left to reach it', () {
    final momentum = calculator.calculate(
      goal: _buildGoal(targetMinor: 100000, lastMilestonePct: 25),
      contributions: const [],
      savedMinor: 30000,
      now: today,
    );

    expect(momentum.nextMilestonePct, 50);
    expect(momentum.amountToNextMilestoneMinor, 20000);
  });

  test('once 100% is already the last crossed milestone, there is no next one', () {
    final momentum = calculator.calculate(
      goal: _buildGoal(lastMilestonePct: 100),
      contributions: const [],
      savedMinor: 100000,
      now: today,
    );

    expect(momentum.nextMilestonePct, isNull);
    expect(momentum.amountToNextMilestoneMinor, isNull);
  });

  test('the amount to the next milestone never goes negative', () {
    final momentum = calculator.calculate(
      goal: _buildGoal(targetMinor: 100000, lastMilestonePct: 0),
      contributions: const [],
      savedMinor: 90000,
      now: today,
    );

    expect(momentum.nextMilestonePct, 25);
    expect(momentum.amountToNextMilestoneMinor, 0);
  });
}
