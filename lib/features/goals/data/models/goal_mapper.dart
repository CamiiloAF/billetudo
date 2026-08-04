import 'package:drift/drift.dart';

import '../../../../core/database/app_database.dart' as db;
import '../../domain/entities/goal.dart';
import '../../domain/entities/goal_draft.dart';

/// Translates between Drift's generated `Goal` rows and the domain [Goal]
/// entity. The only place `*Data`/`*Companion` types meet the domain, so no
/// generated type escapes `data/`.
abstract final class GoalMapper {
  static Goal toEntity(db.Goal row) => Goal(
        id: row.id,
        name: row.name,
        targetMinor: row.targetMinor,
        currency: row.currency,
        accountId: row.accountId,
        targetDate: row.targetDate,
        icon: row.icon,
        completedAt: row.completedAt,
        archivedAt: row.archivedAt,
        lastMilestonePct: row.lastMilestonePct,
        createdAt: row.createdAt,
        updatedAt: row.updatedAt,
        deletedAt: row.deletedAt,
      );

  /// Insert companion. `id` is left to Drift's `clientDefault` (UUID). The
  /// initial `lastMilestonePct`/`completedAt`/`archivedAt` are left at their
  /// column defaults (0/null/null) — a brand new goal starts untouched.
  static db.GoalsCompanion toInsertCompanion(
    GoalDraft draft, {
    required DateTime now,
  }) =>
      db.GoalsCompanion.insert(
        name: draft.name,
        targetMinor: draft.targetMinor,
        currency: draft.currency,
        accountId: Value(draft.accountId),
        targetDate: Value(draft.targetDate),
        icon: Value(draft.icon),
        createdAt: Value(now),
        updatedAt: Value(now.millisecondsSinceEpoch),
      );

  /// Update companion (HU-08). `completedAt`/`lastMilestonePct` are handled
  /// separately by `GoalRepositoryImpl` (they depend on the derived
  /// `savedMinor`, which this mapper does not know about).
  static db.GoalsCompanion toUpdateCompanion(
    GoalDraft draft, {
    required DateTime now,
  }) =>
      db.GoalsCompanion(
        name: Value(draft.name),
        targetMinor: Value(draft.targetMinor),
        currency: Value(draft.currency),
        accountId: Value(draft.accountId),
        targetDate: Value(draft.targetDate),
        icon: Value(draft.icon),
        updatedAt: Value(now.millisecondsSinceEpoch),
      );

  /// HU-09: fija/limpia `archivedAt`.
  static db.GoalsCompanion archiveCompanion({
    required DateTime? archivedAt,
    required DateTime now,
  }) =>
      db.GoalsCompanion(
        archivedAt: Value(archivedAt),
        updatedAt: Value(now.millisecondsSinceEpoch),
      );

  /// HU-10: papelera/undo. Stamps `deletedAt`, never `tombstonedAt`.
  static db.GoalsCompanion softDeleteCompanion({required DateTime now}) =>
      db.GoalsCompanion(
        deletedAt: Value(now),
        updatedAt: Value(now.millisecondsSinceEpoch),
      );

  /// HU-10: undo from the trash. Clears `deletedAt`.
  static db.GoalsCompanion restoreCompanion({required DateTime now}) =>
      db.GoalsCompanion(
        deletedAt: const Value(null),
        updatedAt: Value(now.millisecondsSinceEpoch),
      );

  /// HU-10: vaciar la papelera. Stamps `tombstonedAt`, an irreversible
  /// referential lápida — `Transactions.goalId` may still reference this row.
  static db.GoalsCompanion tombstoneCompanion({required DateTime now}) =>
      db.GoalsCompanion(
        tombstonedAt: Value(now),
        updatedAt: Value(now.millisecondsSinceEpoch),
      );

  /// HU-06/HU-07 reconciliation, applied against the derived `savedMinor`.
  static db.GoalsCompanion progressStateCompanion({
    required DateTime? completedAt,
    required int lastMilestonePct,
    required DateTime now,
  }) =>
      db.GoalsCompanion(
        completedAt: Value(completedAt),
        lastMilestonePct: Value(lastMilestonePct),
        updatedAt: Value(now.millisecondsSinceEpoch),
      );
}
