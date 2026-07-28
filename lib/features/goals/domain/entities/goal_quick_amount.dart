import 'package:equatable/equatable.dart';

/// A user-defined "aporte rápido" chip for a goal (Metas detail, "Aporte
/// rápido" row — design-system/billetudo/pages/metas.md). The two built-in
/// chips ($50.000/$100.000) are never represented as a [GoalQuickAmount]; only
/// the ones the user creates via "+ Nueva" live as rows.
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
