import 'package:equatable/equatable.dart';

/// An "aporte rápido" chip for a goal (Metas detail, "Aporte rápido" row —
/// design-system/billetudo/pages/metas.md). Every chip shown in that row is a
/// [GoalQuickAmount] row: the two default chips ($50.000/$100.000) are seeded
/// by `CreateGoal` right after a goal is created, and the user can add more
/// via "+ Nueva" — both kinds are plain rows with no distinguishing flag, so
/// every chip carries the same delete ("x") affordance.
///
/// Pure domain entity: no Drift types.
class GoalQuickAmount extends Equatable {
  const GoalQuickAmount({
    required this.id,
    required this.goalId,
    required this.amountMinor,
    required this.createdAt,
    required this.updatedAt,
  });

  /// UUID as text.
  final String id;

  final String goalId;

  /// Chip amount in cents. Never `double`, same money rule as everywhere else.
  final int amountMinor;

  final DateTime createdAt;

  /// Epoch millis, not a `DateTime` — see `_SyncColumns.updatedAt`.
  final int updatedAt;

  @override
  List<Object?> get props => [id, goalId, amountMinor, createdAt, updatedAt];
}
