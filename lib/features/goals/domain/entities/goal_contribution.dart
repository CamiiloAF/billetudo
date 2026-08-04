import 'package:equatable/equatable.dart';

/// Which way a movement points against a goal's progress. Mirrors
/// `GoalMovementDirection` stored as text in Drift, declared here so the
/// domain never depends on the database layer.
enum GoalMovementDirection { contribution, withdrawal }

/// A single ledger movement against a `Goal` — the ONLY source of a goal's
/// progress (`Goal` has no stored `savedMinor`; it is always
/// `SUM(contribution) - SUM(withdrawal)` over these rows). Mirrors how
/// `DebtEntry` derives a debt's outstanding balance.
class GoalContribution extends Equatable {
  const GoalContribution({
    required this.id,
    required this.goalId,
    required this.amountMinor,
    required this.direction,
    required this.date,
    required this.createdAt,
    required this.updatedAt,
    this.transactionId,
    this.note,
    this.deletedAt,
  });

  /// UUID as text.
  final String id;

  final String goalId;

  /// Always positive; [direction] carries the sign meaning.
  final int amountMinor;

  final GoalMovementDirection direction;

  /// The date of the movement (user-chosen), not [createdAt].
  final DateTime date;

  /// The `Transaction` this movement mirrors, when it actually moved money (a
  /// real transfer into/out of the goal's linked account). `null` = a
  /// tracking-only contribution/withdrawal that never touched a balance.
  final String? transactionId;

  final String? note;

  final DateTime createdAt;

  /// Epoch millis, not a `DateTime` — see `_SyncColumns.updatedAt`.
  final int updatedAt;

  /// Hidden together with the goal when it is trashed/tombstoned (HU-10).
  final DateTime? deletedAt;

  /// Whether this movement actually moved money between accounts.
  bool get movedMoney => transactionId != null;

  /// The signed effect on the goal's `savedMinor` (+ contribution, −
  /// withdrawal).
  int get signedMinor => switch (direction) {
        GoalMovementDirection.contribution => amountMinor,
        GoalMovementDirection.withdrawal => -amountMinor,
      };

  @override
  List<Object?> get props => [
        id,
        goalId,
        amountMinor,
        direction,
        date,
        transactionId,
        note,
        createdAt,
        updatedAt,
        deletedAt,
      ];
}
