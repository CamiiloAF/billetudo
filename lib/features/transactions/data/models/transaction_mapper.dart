import 'package:drift/drift.dart';

import '../../../../core/database/app_database.dart' as db;
import '../../domain/entities/transaction.dart';
import '../../domain/entities/transaction_draft.dart';

/// Translates between Drift's generated `Transaction` rows and the domain
/// [Transaction] entity. The only place where `*Data`/`*Companion` types meet
/// the domain, so no generated type ever escapes `data/`.
///
/// Enums are mapped explicitly (not by index) because they are stored as text
/// for parity with Postgres: the domain owns its own enum, and the two are
/// matched by meaning, not by declaration order.
abstract final class TransactionMapper {
  static Transaction toEntity(db.Transaction row) => Transaction(
        id: row.id,
        accountId: row.accountId,
        categoryId: row.categoryId,
        amountMinor: row.amountMinor,
        currency: row.currency,
        type: typeToDomain(row.type),
        date: row.date,
        note: row.note,
        source: _sourceToDomain(row.source),
        transferAccountId: row.transferAccountId,
        scheduledPaymentId: row.scheduledPaymentId,
        goalId: row.goalId,
        debtId: row.debtId,
        createdAt: row.createdAt,
        updatedAt: row.updatedAt,
      );

  /// Insert companion. `id` is left to Drift's `clientDefault` (UUID).
  static db.TransactionsCompanion toInsertCompanion(
    TransactionDraft draft, {
    required DateTime now,
  }) =>
      db.TransactionsCompanion.insert(
        accountId: draft.accountId,
        categoryId: Value(draft.categoryId),
        amountMinor: draft.amountMinor,
        currency: draft.currency,
        type: typeToDb(draft.type),
        date: draft.date,
        note: Value(draft.note),
        source: Value(_sourceToDb(draft.source)),
        transferAccountId: Value(draft.transferAccountId),
        scheduledPaymentId: Value(draft.scheduledPaymentId),
        goalId: Value(draft.goalId),
        debtId: Value(draft.debtId),
        createdAt: Value(now),
        updatedAt: Value(now.millisecondsSinceEpoch),
      );

  /// Update companion (HU-04). `source` is deliberately absent: it is
  /// immutable once created, so an update must never touch that column.
  /// Every nullable field is written explicitly (`Value(null)` rather than
  /// `absent()`) so clearing one in the form actually clears its old data
  /// instead of silently keeping it.
  static db.TransactionsCompanion toUpdateCompanion(
    TransactionDraft draft, {
    required DateTime now,
  }) =>
      db.TransactionsCompanion(
        accountId: Value(draft.accountId),
        categoryId: Value(draft.categoryId),
        amountMinor: Value(draft.amountMinor),
        currency: Value(draft.currency),
        type: Value(typeToDb(draft.type)),
        date: Value(draft.date),
        note: Value(draft.note),
        transferAccountId: Value(draft.transferAccountId),
        scheduledPaymentId: Value(draft.scheduledPaymentId),
        goalId: Value(draft.goalId),
        debtId: Value(draft.debtId),
        updatedAt: Value(now.millisecondsSinceEpoch),
      );

  /// HU-05: papelera/undo. Stamps `deletedAt`, never `tombstonedAt` — nothing
  /// references a transaction's id, so there is no referential-integrity
  /// tombstone to protect here.
  static db.TransactionsCompanion softDeleteCompanion(
          {required DateTime now}) =>
      db.TransactionsCompanion(
          deletedAt: Value(now), updatedAt: Value(now.millisecondsSinceEpoch));

  /// HU-05: undo from the snackbar.
  static db.TransactionsCompanion restoreCompanion({required DateTime now}) =>
      db.TransactionsCompanion(
        deletedAt: const Value(null),
        updatedAt: Value(now.millisecondsSinceEpoch),
      );

  static db.EntryType typeToDb(TransactionType type) => switch (type) {
        TransactionType.income => db.EntryType.income,
        TransactionType.expense => db.EntryType.expense,
        TransactionType.transfer => db.EntryType.transfer,
      };

  static TransactionType typeToDomain(db.EntryType type) => switch (type) {
        db.EntryType.income => TransactionType.income,
        db.EntryType.expense => TransactionType.expense,
        db.EntryType.transfer => TransactionType.transfer,
      };

  static db.TxSource _sourceToDb(TransactionSource source) => switch (source) {
        TransactionSource.manual => db.TxSource.manual,
        TransactionSource.voice => db.TxSource.voice,
        TransactionSource.ocr => db.TxSource.ocr,
        TransactionSource.notification => db.TxSource.notification,
        TransactionSource.imported => db.TxSource.imported,
        TransactionSource.scheduled => db.TxSource.scheduled,
      };

  static TransactionSource _sourceToDomain(db.TxSource source) =>
      switch (source) {
        db.TxSource.manual => TransactionSource.manual,
        db.TxSource.voice => TransactionSource.voice,
        db.TxSource.ocr => TransactionSource.ocr,
        db.TxSource.notification => TransactionSource.notification,
        db.TxSource.imported => TransactionSource.imported,
        db.TxSource.scheduled => TransactionSource.scheduled,
      };
}
