import 'package:billetudo/features/goals/domain/entities/goal.dart';
import 'package:billetudo/features/goals/domain/entities/goal_with_progress.dart';
import 'package:billetudo/features/goals/domain/usecases/watch_goals.dart';
import 'package:flutter_test/flutter_test.dart';

GoalWithProgress _goal({
  required String id,
  DateTime? targetDate,
  DateTime? completedAt,
}) =>
    GoalWithProgress(
      goal: Goal(
        id: id,
        name: id,
        targetMinor: 100000,
        currency: 'COP',
        lastMilestonePct: 0,
        createdAt: DateTime(2026, 1, 1),
        updatedAt: DateTime(2026, 1, 1).millisecondsSinceEpoch,
        targetDate: targetDate,
        completedAt: completedAt,
      ),
      savedMinor: 0,
      displayedPercent: 0,
      remainingMinor: 100000,
    );

void main() {
  test(
    'HU-11: en curso con fecha (más próxima primero), luego sin fecha, luego '
    'cumplidas al final',
    () {
      final farDate = _goal(id: 'far', targetDate: DateTime(2027, 6, 1));
      final nearDate = _goal(id: 'near', targetDate: DateTime(2026, 9, 1));
      final noDate = _goal(id: 'no-date');
      final completed = _goal(id: 'done', completedAt: DateTime(2026, 5, 1));

      final sorted = WatchGoals.sorted([farDate, completed, noDate, nearDate]);

      expect(sorted.map((g) => g.goal.id), ['near', 'far', 'no-date', 'done']);
    },
  );

  test('una meta cumplida con fecha igual va al final, no ordenada por fecha', () {
    final completedWithDate =
        _goal(id: 'done', targetDate: DateTime(2026, 8, 1), completedAt: DateTime(2026, 5, 1));
    final inProgress = _goal(id: 'active', targetDate: DateTime(2026, 12, 1));

    final sorted = WatchGoals.sorted([completedWithDate, inProgress]);

    expect(sorted.map((g) => g.goal.id), ['active', 'done']);
  });
}
