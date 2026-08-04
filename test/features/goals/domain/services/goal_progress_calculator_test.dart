import 'package:billetudo/features/goals/domain/entities/goal.dart';
import 'package:billetudo/features/goals/domain/entities/goal_contribution.dart';
import 'package:billetudo/features/goals/domain/services/goal_progress_calculator.dart';
import 'package:flutter_test/flutter_test.dart';

Goal _buildGoal({
  int targetMinor = 100000,
  DateTime? completedAt,
  int lastMilestonePct = 0,
}) =>
    Goal(
      id: 'goal-1',
      name: 'Vacaciones',
      targetMinor: targetMinor,
      currency: 'COP',
      lastMilestonePct: lastMilestonePct,
      createdAt: DateTime(2026, 1, 1),
      updatedAt: DateTime(2026, 1, 1).millisecondsSinceEpoch,
      completedAt: completedAt,
    );

GoalContribution _movement({
  required int amountMinor,
  required GoalMovementDirection direction,
}) =>
    GoalContribution(
      id: 'm-${amountMinor}_${direction.name}',
      goalId: 'goal-1',
      amountMinor: amountMinor,
      direction: direction,
      date: DateTime(2026, 2, 1),
      createdAt: DateTime(2026, 2, 1),
      updatedAt: DateTime(2026, 2, 1).millisecondsSinceEpoch,
    );

void main() {
  const calculator = GoalProgressCalculator();

  group('deriveSavedMinor', () {
    test('SUM(contribution) - SUM(withdrawal), never stored', () {
      final saved = calculator.deriveSavedMinor([
        _movement(amountMinor: 50000, direction: GoalMovementDirection.contribution),
        _movement(amountMinor: 20000, direction: GoalMovementDirection.contribution),
        _movement(amountMinor: 10000, direction: GoalMovementDirection.withdrawal),
      ]);

      expect(saved, 60000);
    });

    test('un histórico vacío es savedMinor 0', () {
      expect(calculator.deriveSavedMinor(const []), 0);
    });
  });

  group('calculate — porcentaje mostrado', () {
    test('acota al 100% aunque savedMinor supere targetMinor', () {
      final progress = calculator.calculate(
        goal: _buildGoal(targetMinor: 100000),
        contributions: [
          _movement(amountMinor: 150000, direction: GoalMovementDirection.contribution),
        ],
      );

      expect(progress.displayedPercent, 100);
      expect(progress.savedMinor, 150000);
      expect(progress.remainingMinor, 0);
    });

    test('redondea hacia abajo un porcentaje fraccional', () {
      final progress = calculator.calculate(
        goal: _buildGoal(targetMinor: 300000),
        contributions: [
          _movement(amountMinor: 100000, direction: GoalMovementDirection.contribution),
        ],
      );

      expect(progress.displayedPercent, 33);
      expect(progress.remainingMinor, 200000);
    });

    test(
      'HU-07: una meta cumplida congela el porcentaje mostrado en 100% aunque '
      'un retiro baje el savedMinor real',
      () {
        final progress = calculator.calculate(
          goal: _buildGoal(targetMinor: 100000, completedAt: DateTime(2026, 3, 1)),
          contributions: [
            _movement(
              amountMinor: 100000,
              direction: GoalMovementDirection.contribution,
            ),
            _movement(
              amountMinor: 40000,
              direction: GoalMovementDirection.withdrawal,
            ),
          ],
        );

        // The REAL derived figure keeps reflecting the withdrawal...
        expect(progress.savedMinor, 60000);
        // ...but the shown percentage and "remaining" stay frozen.
        expect(progress.displayedPercent, 100);
        expect(progress.remainingMinor, 0);
      },
    );
  });
}
