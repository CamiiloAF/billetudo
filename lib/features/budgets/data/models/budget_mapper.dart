import 'package:drift/drift.dart';

import '../../../../core/database/app_database.dart' as db;
import '../../domain/entities/budget.dart';
import '../../domain/entities/budget_draft.dart';

/// Translates between Drift's generated rows and the Budgets domain entities.
/// The only place where `*Data`/`*Companion` types meet the domain, so no
/// generated type ever escapes `data/`.
///
/// Enums are mapped by meaning (not index): they are stored as text for parity
/// with Postgres.
abstract final class BudgetMapper {
  static Budget toEntity(db.Budget row) => Budget(
        id: row.id,
        name: row.name,
        icon: row.icon,
        amountMinor: row.amountMinor,
        currency: row.currency,
        period: _periodToDomain(row.period),
        startDate: row.startDate,
        recurring: row.recurring,
        endDate: row.endDate,
        archivedAt: row.archivedAt,
        alertThresholdPct: row.alertThresholdPct,
        rollover: row.rollover,
        createdAt: row.createdAt,
        updatedAt: row.updatedAt,
      );

  /// Insert companion. `id` is left to Drift's `clientDefault` (UUID).
  static db.BudgetsCompanion toInsertCompanion(
    BudgetDraft draft, {
    required DateTime now,
  }) =>
      db.BudgetsCompanion.insert(
        name: draft.name,
        amountMinor: draft.amountMinor,
        currency: draft.currency,
        period: _periodToDb(draft.period),
        startDate: draft.startDate,
        icon: Value(draft.icon),
        recurring: Value(draft.recurring),
        endDate: Value(draft.endDate),
        alertThresholdPct: Value(draft.alertThresholdPct),
        rollover: Value(draft.rollover),
        createdAt: Value(now),
        updatedAt: Value(now.millisecondsSinceEpoch),
      );

  /// Update companion. Nullable fields are written explicitly (`Value(null)`
  /// rather than `absent()`) so clearing an end date or a threshold actually
  /// clears it (HU-09).
  static db.BudgetsCompanion toUpdateCompanion(
    BudgetDraft draft, {
    required DateTime now,
  }) =>
      db.BudgetsCompanion(
        name: Value(draft.name),
        icon: Value(draft.icon),
        amountMinor: Value(draft.amountMinor),
        currency: Value(draft.currency),
        period: Value(_periodToDb(draft.period)),
        startDate: Value(draft.startDate),
        recurring: Value(draft.recurring),
        endDate: Value(draft.endDate),
        alertThresholdPct: Value(draft.alertThresholdPct),
        rollover: Value(draft.rollover),
        updatedAt: Value(now.millisecondsSinceEpoch),
      );

  static db.BudgetsCompanion archivedCompanion({
    required DateTime? archivedAt,
    required DateTime now,
  }) =>
      db.BudgetsCompanion(
        archivedAt: Value(archivedAt),
        updatedAt: Value(now.millisecondsSinceEpoch),
      );

  static db.BudgetsCompanion deletedCompanion({required DateTime now}) =>
      db.BudgetsCompanion(
        deletedAt: Value(now),
        updatedAt: Value(now.millisecondsSinceEpoch),
      );

  static db.BudgetPeriod _periodToDb(BudgetPeriod period) => switch (period) {
        BudgetPeriod.weekly => db.BudgetPeriod.weekly,
        BudgetPeriod.biweekly => db.BudgetPeriod.biweekly,
        BudgetPeriod.monthly => db.BudgetPeriod.monthly,
        BudgetPeriod.yearly => db.BudgetPeriod.yearly,
        BudgetPeriod.custom => db.BudgetPeriod.custom,
      };

  static BudgetPeriod _periodToDomain(db.BudgetPeriod period) =>
      switch (period) {
        db.BudgetPeriod.weekly => BudgetPeriod.weekly,
        db.BudgetPeriod.biweekly => BudgetPeriod.biweekly,
        db.BudgetPeriod.monthly => BudgetPeriod.monthly,
        db.BudgetPeriod.yearly => BudgetPeriod.yearly,
        db.BudgetPeriod.custom => BudgetPeriod.custom,
      };
}
