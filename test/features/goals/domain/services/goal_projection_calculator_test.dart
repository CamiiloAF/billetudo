import 'package:billetudo/features/goals/domain/entities/goal.dart';
import 'package:billetudo/features/goals/domain/entities/goal_contribution.dart';
import 'package:billetudo/features/goals/domain/entities/goal_projection.dart';
import 'package:billetudo/features/goals/domain/services/goal_projection_calculator.dart';
import 'package:flutter_test/flutter_test.dart';

Goal _buildGoal({DateTime? targetDate, DateTime? createdAt, int targetMinor = 1200000}) =>
    Goal(
      id: 'goal-1',
      name: 'Vacaciones',
      targetMinor: targetMinor,
      currency: 'COP',
      lastMilestonePct: 0,
      createdAt: createdAt ?? DateTime(2026, 1, 1),
      updatedAt: (createdAt ?? DateTime(2026, 1, 1)).millisecondsSinceEpoch,
      targetDate: targetDate,
    );

GoalContribution _contribution(DateTime date, int amountMinor) => GoalContribution(
      id: 'm-${date.toIso8601String()}',
      goalId: 'goal-1',
      amountMinor: amountMinor,
      direction: GoalMovementDirection.contribution,
      date: date,
      createdAt: date,
      updatedAt: date.millisecondsSinceEpoch,
    );

void main() {
  const calculator = GoalProjectionCalculator();
  final today = DateTime(2026, 7, 15);

  test('sin targetDate no hay proyección de fecha', () {
    final projection = calculator.calculate(
      goal: _buildGoal(),
      contributions: const [],
      savedMinor: 0,
      now: today,
    );

    expect(projection.kind, GoalProjectionKind.noTargetDate);
  });

  test('targetDate ya vencida: overdue, sin estado de fracaso', () {
    final projection = calculator.calculate(
      goal: _buildGoal(targetDate: DateTime(2026, 6, 1)),
      contributions: const [],
      savedMinor: 0,
      now: today,
    );

    expect(projection.kind, GoalProjectionKind.overdue);
  });

  test(
    'sin historial suficiente (goal recién creada) muestra el aporte '
    'mensual necesario, no una fecha',
    () {
      final projection = calculator.calculate(
        goal: _buildGoal(
          targetDate: DateTime(2026, 12, 15),
          createdAt: DateTime(2026, 7, 1),
          targetMinor: 500000,
        ),
        contributions: [_contribution(DateTime(2026, 7, 10), 100000)],
        savedMinor: 100000,
        now: today,
      );

      expect(projection.kind, GoalProjectionKind.insufficientHistory);
      expect(projection.monthlyContributionNeededMinor, isNotNull);
      expect(projection.estimatedDate, isNull);
    },
  );

  test('cero movimientos también cuenta como historial insuficiente', () {
    final projection = calculator.calculate(
      goal: _buildGoal(
        targetDate: DateTime(2026, 12, 15),
        createdAt: DateTime(2025, 1, 1),
      ),
      contributions: const [],
      savedMinor: 0,
      now: today,
    );

    expect(projection.kind, GoalProjectionKind.insufficientHistory);
  });

  test(
    'ritmo positivo de los últimos 3 meses completos proyecta una fecha',
    () {
      final projection = calculator.calculate(
        goal: _buildGoal(
          targetDate: DateTime(2027, 1, 1),
          createdAt: DateTime(2025, 1, 1),
          targetMinor: 1200000,
        ),
        contributions: [
          _contribution(DateTime(2026, 4, 10), 100000),
          _contribution(DateTime(2026, 5, 10), 100000),
          _contribution(DateTime(2026, 6, 10), 100000),
        ],
        savedMinor: 300000,
        now: today,
      );

      expect(projection.kind, GoalProjectionKind.projected);
      expect(projection.estimatedDate, isNotNull);
      expect(projection.paceMinorPerMonth, 100000);
    },
  );

  test('ritmo cero o negativo: muestra aporte mensual necesario, no fecha', () {
    final projection = calculator.calculate(
      goal: _buildGoal(
        targetDate: DateTime(2027, 1, 1),
        createdAt: DateTime(2025, 1, 1),
      ),
      contributions: [
        _contribution(DateTime(2026, 4, 10), 50000),
        GoalContribution(
          id: 'w-1',
          goalId: 'goal-1',
          amountMinor: 50000,
          direction: GoalMovementDirection.withdrawal,
          date: DateTime(2026, 5, 10),
          createdAt: DateTime(2026, 5, 10),
          updatedAt: DateTime(2026, 5, 10).millisecondsSinceEpoch,
        ),
      ],
      savedMinor: 0,
      now: today,
    );

    expect(projection.kind, GoalProjectionKind.noPace);
    expect(projection.monthlyContributionNeededMinor, isNotNull);
  });
}
