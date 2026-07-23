import 'package:drift/drift.dart';

import '../../../../core/database/app_database.dart' as db;
import '../../domain/entities/debt.dart';
import '../../domain/entities/debt_draft.dart';

/// Translates between Drift's generated `Debt` rows and the domain [Debt]
/// entity. The only place `*Data`/`*Companion` types meet the domain, so no
/// generated type escapes `data/`.
///
/// Enums are mapped explicitly (not by index): they are stored as text for
/// Postgres parity, so the two enums are matched by meaning, not by order.
abstract final class DebtMapper {
  static Debt toEntity(db.Debt row) => Debt(
        id: row.id,
        name: row.name,
        direction: directionToDomain(row.direction),
        principalMinor: row.principalMinor,
        currency: row.currency,
        accrualMode: accrualModeToDomain(row.accrualMode),
        startDate: row.startDate,
        counterparty: row.counterparty,
        dueDate: row.dueDate,
        interestRateBps: row.interestRateBps,
        createdAt: row.createdAt,
        updatedAt: row.updatedAt,
        deletedAt: row.deletedAt,
        initialTransactionId: row.initialTransactionId,
      );

  /// Insert companion. `id` is left to Drift's `clientDefault` (UUID).
  static db.DebtsCompanion toInsertCompanion(
    DebtDraft draft, {
    required DateTime now,
  }) =>
      db.DebtsCompanion.insert(
        name: draft.name,
        direction: directionToDb(draft.direction),
        principalMinor: draft.principalMinor,
        currency: draft.currency,
        accrualMode: Value(accrualModeToDb(draft.accrualMode)),
        // `startDate` has no Drift default (the PowerSync view constraint,
        // decision #14), so it is stamped explicitly on every insert; a draft
        // without one falls back to the insert timestamp (the row's birthday).
        startDate: Value(draft.startDate ?? now),
        counterparty: Value(draft.counterparty),
        dueDate: Value(draft.dueDate),
        interestRateBps: Value(draft.interestRateBps),
        createdAt: Value(now),
        updatedAt: Value(now.millisecondsSinceEpoch),
      );

  /// Update companion (HU-05). Every nullable field is written explicitly
  /// (`Value(null)` rather than `absent()`) so clearing one in the form
  /// actually clears its old data.
  static db.DebtsCompanion toUpdateCompanion(
    DebtDraft draft, {
    required DateTime now,
  }) =>
      db.DebtsCompanion(
        name: Value(draft.name),
        direction: Value(directionToDb(draft.direction)),
        principalMinor: Value(draft.principalMinor),
        currency: Value(draft.currency),
        accrualMode: Value(accrualModeToDb(draft.accrualMode)),
        // `startDate` is required in the form (never cleared), so it is left
        // untouched when a caller omits it rather than wiped to null.
        startDate:
            draft.startDate == null ? const Value.absent() : Value(draft.startDate),
        counterparty: Value(draft.counterparty),
        dueDate: Value(draft.dueDate),
        interestRateBps: Value(draft.interestRateBps),
        updatedAt: Value(now.millisecondsSinceEpoch),
      );

  /// HU-05: papelera/undo. Stamps `deletedAt`, never `tombstonedAt`.
  static db.DebtsCompanion softDeleteCompanion({required DateTime now}) =>
      db.DebtsCompanion(
        deletedAt: Value(now),
        updatedAt: Value(now.millisecondsSinceEpoch),
      );

  /// HU-05: undo from the snackbar/trash. Clears `deletedAt`.
  static db.DebtsCompanion restoreCompanion({required DateTime now}) =>
      db.DebtsCompanion(
        deletedAt: const Value(null),
        updatedAt: Value(now.millisecondsSinceEpoch),
      );

  static db.DebtDirection directionToDb(DebtDirection direction) =>
      switch (direction) {
        DebtDirection.iOwe => db.DebtDirection.iOwe,
        DebtDirection.owedToMe => db.DebtDirection.owedToMe,
      };

  static DebtDirection directionToDomain(db.DebtDirection direction) =>
      switch (direction) {
        db.DebtDirection.iOwe => DebtDirection.iOwe,
        db.DebtDirection.owedToMe => DebtDirection.owedToMe,
      };

  static db.DebtAccrualMode accrualModeToDb(DebtAccrualMode mode) =>
      switch (mode) {
        DebtAccrualMode.manual => db.DebtAccrualMode.manual,
        DebtAccrualMode.auto => db.DebtAccrualMode.auto,
      };

  static DebtAccrualMode accrualModeToDomain(db.DebtAccrualMode mode) =>
      switch (mode) {
        db.DebtAccrualMode.manual => DebtAccrualMode.manual,
        db.DebtAccrualMode.auto => DebtAccrualMode.auto,
      };
}
