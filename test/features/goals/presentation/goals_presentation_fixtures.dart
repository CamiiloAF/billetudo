import 'package:billetudo/features/goals/domain/entities/goal.dart';
import 'package:billetudo/features/goals/domain/entities/goal_contribution.dart';
import 'package:billetudo/features/goals/domain/entities/goal_detail.dart';
import 'package:billetudo/features/goals/domain/entities/goal_momentum.dart';
import 'package:billetudo/features/goals/domain/entities/goal_projection.dart';
import 'package:billetudo/features/goals/domain/entities/goal_quick_amount.dart';
import 'package:billetudo/features/goals/domain/entities/goal_with_progress.dart';

Goal buildGoal({
  String id = 'g1',
  String name = 'Viaje a Cartagena',
  int targetMinor = 1000000,
  String currency = 'COP',
  int lastMilestonePct = 0,
  String? accountId,
  DateTime? targetDate,
  DateTime? completedAt,
  DateTime? archivedAt,
  DateTime? deletedAt,
}) =>
    Goal(
      id: id,
      name: name,
      targetMinor: targetMinor,
      currency: currency,
      lastMilestonePct: lastMilestonePct,
      createdAt: DateTime(2026, 1, 1),
      updatedAt: DateTime(2026, 1, 1).millisecondsSinceEpoch,
      accountId: accountId,
      targetDate: targetDate,
      completedAt: completedAt,
      archivedAt: archivedAt,
      deletedAt: deletedAt,
    );

GoalWithProgress buildGoalWithProgress({
  Goal? goal,
  int savedMinor = 0,
  int displayedPercent = 0,
  int? remainingMinor,
  GoalCoherenceSignal? coherence,
  GoalMomentum? momentum,
}) {
  final resolvedGoal = goal ?? buildGoal();
  return GoalWithProgress(
    goal: resolvedGoal,
    savedMinor: savedMinor,
    displayedPercent: displayedPercent,
    remainingMinor: remainingMinor ?? (resolvedGoal.targetMinor - savedMinor),
    coherence: coherence,
    momentum: momentum,
  );
}

GoalContribution buildGoalContribution({
  String id = 'm1',
  String goalId = 'g1',
  int amountMinor = 50000,
  GoalMovementDirection direction = GoalMovementDirection.contribution,
  DateTime? date,
  String? transactionId,
  String? note,
}) =>
    GoalContribution(
      id: id,
      goalId: goalId,
      amountMinor: amountMinor,
      direction: direction,
      date: date ?? DateTime(2026, 7, 5),
      createdAt: date ?? DateTime(2026, 7, 5),
      updatedAt: (date ?? DateTime(2026, 7, 5)).millisecondsSinceEpoch,
      transactionId: transactionId,
      note: note,
    );

GoalQuickAmount buildGoalQuickAmount({
  String id = 'qa1',
  String goalId = 'g1',
  int amountMinor = 200000,
  DateTime? createdAt,
}) =>
    GoalQuickAmount(
      id: id,
      goalId: goalId,
      amountMinor: amountMinor,
      createdAt: createdAt ?? DateTime(2026, 7, 1),
      updatedAt: (createdAt ?? DateTime(2026, 7, 1)).millisecondsSinceEpoch,
    );

GoalDetail buildGoalDetail({
  GoalWithProgress? progress,
  GoalProjection projection = const GoalProjection(
    kind: GoalProjectionKind.noTargetDate,
  ),
  GoalMomentum momentum = const GoalMomentum(streakWeeks: 0),
  List<GoalContribution> history = const [],
  bool accountTombstoned = false,
}) =>
    GoalDetail(
      progress: progress ?? buildGoalWithProgress(),
      projection: projection,
      momentum: momentum,
      history: history,
      accountTombstoned: accountTombstoned,
    );
