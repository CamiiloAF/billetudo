import 'package:drift/drift.dart';

import '../../../../core/database/app_database.dart' as db;
import '../../domain/entities/debt_entry.dart';
import '../../domain/entities/debt_entry_draft.dart';

/// Translates between Drift's generated `DebtEntry` rows and the domain
/// [DebtEntry] entity. Kinds are mapped explicitly by meaning (stored as text
/// for Postgres parity).
abstract final class DebtEntryMapper {
  static DebtEntry toEntity(db.DebtEntry row) => DebtEntry(
        id: row.id,
        debtId: row.debtId,
        kind: kindToDomain(row.kind),
        amountMinor: row.amountMinor,
        entryDate: row.entryDate,
        note: row.note,
        rateBpsSnapshot: row.rateBpsSnapshot,
        createdAt: row.createdAt,
        updatedAt: row.updatedAt,
        deletedAt: row.deletedAt,
      );

  static db.DebtEntriesCompanion toInsertCompanion(
    DebtEntryDraft draft, {
    required DateTime now,
  }) =>
      db.DebtEntriesCompanion.insert(
        debtId: draft.debtId,
        kind: kindToDb(draft.kind),
        amountMinor: draft.amountMinor,
        entryDate: draft.entryDate,
        note: Value(draft.note),
        rateBpsSnapshot: Value(draft.rateBpsSnapshot),
        createdAt: Value(now),
        updatedAt: Value(now.millisecondsSinceEpoch),
      );

  static db.DebtEntryKind kindToDb(DebtEntryKind kind) => switch (kind) {
        DebtEntryKind.interestAccrual => db.DebtEntryKind.interestAccrual,
        DebtEntryKind.manualAdjustment => db.DebtEntryKind.manualAdjustment,
        DebtEntryKind.payment => db.DebtEntryKind.payment,
        DebtEntryKind.disbursement => db.DebtEntryKind.disbursement,
      };

  static DebtEntryKind kindToDomain(db.DebtEntryKind kind) => switch (kind) {
        db.DebtEntryKind.interestAccrual => DebtEntryKind.interestAccrual,
        db.DebtEntryKind.manualAdjustment => DebtEntryKind.manualAdjustment,
        db.DebtEntryKind.payment => DebtEntryKind.payment,
        db.DebtEntryKind.disbursement => DebtEntryKind.disbursement,
      };
}
