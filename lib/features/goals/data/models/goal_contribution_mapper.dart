import 'package:drift/drift.dart';

import '../../../../core/database/app_database.dart' as db;
import '../../domain/entities/goal_contribution.dart';
import '../../domain/entities/goal_contribution_draft.dart';

/// Translates between Drift's generated `GoalContribution` rows and the
/// domain [GoalContribution] entity. Enums are mapped explicitly (not by
/// index): they are stored as text for Postgres parity.
abstract final class GoalContributionMapper {
  static GoalContribution toEntity(db.GoalContribution row) => GoalContribution(
        id: row.id,
        goalId: row.goalId,
        amountMinor: row.amountMinor,
        direction: directionToDomain(row.direction),
        date: row.date,
        transactionId: row.transactionId,
        note: row.note,
        createdAt: row.createdAt,
        updatedAt: row.updatedAt,
        deletedAt: row.deletedAt,
      );

  /// Insert companion for a draft-backed movement (HU-03/HU-04). `id` is left
  /// to Drift's `clientDefault`. [transactionId] is passed separately because
  /// a money-moving movement's id is only known after the transfer
  /// `Transaction` is inserted in the same atomic write.
  static db.GoalContributionsCompanion toInsertCompanion(
    GoalContributionDraft draft, {
    required DateTime now,
    String? transactionId,
  }) =>
      db.GoalContributionsCompanion.insert(
        goalId: draft.goalId,
        amountMinor: draft.amountMinor,
        direction: directionToDb(draft.direction),
        date: draft.date,
        transactionId: Value(transactionId),
        note: Value(draft.note),
        createdAt: Value(now),
        updatedAt: Value(now.millisecondsSinceEpoch),
      );

  /// Insert companion for HU-01's "avance ya existente" and for HU-03's
  /// "enlazar un movimiento existente".
  static db.GoalContributionsCompanion toLinkedInsertCompanion({
    required String goalId,
    required int amountMinor,
    required GoalMovementDirection direction,
    required DateTime date,
    required DateTime now,
    String? transactionId,
    String? note,
  }) =>
      db.GoalContributionsCompanion.insert(
        goalId: goalId,
        amountMinor: amountMinor,
        direction: directionToDb(direction),
        date: date,
        transactionId: Value(transactionId),
        note: Value(note),
        createdAt: Value(now),
        updatedAt: Value(now.millisecondsSinceEpoch),
      );

  static db.GoalMovementDirection directionToDb(GoalMovementDirection direction) =>
      switch (direction) {
        GoalMovementDirection.contribution => db.GoalMovementDirection.contribution,
        GoalMovementDirection.withdrawal => db.GoalMovementDirection.withdrawal,
      };

  static GoalMovementDirection directionToDomain(db.GoalMovementDirection direction) =>
      switch (direction) {
        db.GoalMovementDirection.contribution => GoalMovementDirection.contribution,
        db.GoalMovementDirection.withdrawal => GoalMovementDirection.withdrawal,
      };
}
