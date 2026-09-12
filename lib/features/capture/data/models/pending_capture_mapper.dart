import 'package:drift/drift.dart';

import '../../../../core/database/app_database.dart' as db;
import '../../../transactions/domain/entities/transaction.dart';
import '../../domain/entities/capture_ingestion.dart';
import '../../domain/entities/pending_capture.dart';

/// Translates between Drift's generated `PendingCapture` rows and the domain
/// [PendingCapture] entity, and builds the companions of every write.
///
/// Drift types stop here: nothing generated (`*Data`, `*Companion`) leaves
/// `data/`.
abstract final class PendingCaptureMapper {
  static PendingCapture toEntity(db.PendingCapture row) => PendingCapture(
        id: row.id,
        source: _sourceToDomain(row.source),
        sourcePackage: row.sourcePackage,
        sourceRuleId: row.sourceRuleId,
        postedAt: row.postedAt,
        amountMinor: row.amountMinor,
        currency: row.currency,
        entryType: _entryTypeToDomain(row.entryType),
        merchantRaw: row.merchantRaw,
        accountHint: row.accountHint,
        suggestedAccountId: row.suggestedAccountId,
        suggestedCategoryId: row.suggestedCategoryId,
        status: _statusToDomain(row.status),
        transactionId: row.transactionId,
        duplicateOfTransactionId: row.duplicateOfTransactionId,
        createdAt: row.createdAt,
        updatedAt: row.updatedAt,
      );

  /// A brand-new inbox row. `status` is left to the table's `pending`
  /// default: ingestion has exactly one outcome, and spelling it out here
  /// would be a second place where "captures arrive pending" could drift.
  static db.PendingCapturesCompanion insertCompanion(
    CaptureIngestion ingestion, {
    required DateTime now,
  }) {
    final parsed = ingestion.parsed;
    return db.PendingCapturesCompanion.insert(
      source: _sourceToDb(parsed.source),
      sourcePackage: parsed.sourcePackage,
      sourceRuleId: Value(parsed.sourceRuleId),
      postedAt: parsed.postedAt,
      amountMinor: parsed.amountMinor,
      currency: parsed.currency,
      entryType: _entryTypeToDb(parsed.entryType),
      merchantRaw: Value(parsed.merchantRaw),
      accountHint: Value(parsed.accountHint),
      suggestedAccountId: Value(ingestion.suggestedAccountId),
      suggestedCategoryId: Value(ingestion.suggestedCategoryId),
      createdAt: Value(now),
      updatedAt: Value(now.millisecondsSinceEpoch),
    );
  }

  /// HU-05: the capture became a real movement.
  static db.PendingCapturesCompanion confirmCompanion({
    required String transactionId,
    required DateTime now,
  }) =>
      db.PendingCapturesCompanion(
        status: const Value(db.CaptureStatus.confirmed),
        transactionId: Value(transactionId),
        updatedAt: Value(now.millisecondsSinceEpoch),
      );

  /// HU-05: the user threw it away. Still not a `deletedAt` — the row waits
  /// for the undo window and is then physically purged.
  static db.PendingCapturesCompanion discardCompanion({
    required DateTime now,
    String? duplicateOfTransactionId,
  }) =>
      db.PendingCapturesCompanion(
        status: const Value(db.CaptureStatus.discarded),
        duplicateOfTransactionId: Value(duplicateOfTransactionId),
        updatedAt: Value(now.millisecondsSinceEpoch),
      );

  /// Undo of the discard. Clears the duplicate mark too: it recorded why the
  /// capture was thrown away, and the user just said that reason was wrong.
  static db.PendingCapturesCompanion restoreCompanion(
          {required DateTime now}) =>
      db.PendingCapturesCompanion(
        status: const Value(db.CaptureStatus.pending),
        duplicateOfTransactionId: const Value(null),
        updatedAt: Value(now.millisecondsSinceEpoch),
      );

  static CaptureStatus _statusToDomain(db.CaptureStatus status) =>
      switch (status) {
        db.CaptureStatus.pending => CaptureStatus.pending,
        db.CaptureStatus.confirmed => CaptureStatus.confirmed,
        db.CaptureStatus.discarded => CaptureStatus.discarded,
      };

  static TransactionType _entryTypeToDomain(db.EntryType type) =>
      switch (type) {
        db.EntryType.income => TransactionType.income,
        db.EntryType.expense => TransactionType.expense,
        db.EntryType.transfer => TransactionType.transfer,
      };

  static db.EntryType _entryTypeToDb(TransactionType type) => switch (type) {
        TransactionType.income => db.EntryType.income,
        TransactionType.expense => db.EntryType.expense,
        TransactionType.transfer => db.EntryType.transfer,
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

  static db.TxSource _sourceToDb(TransactionSource source) => switch (source) {
        TransactionSource.manual => db.TxSource.manual,
        TransactionSource.voice => db.TxSource.voice,
        TransactionSource.ocr => db.TxSource.ocr,
        TransactionSource.notification => db.TxSource.notification,
        TransactionSource.imported => db.TxSource.imported,
        TransactionSource.scheduled => db.TxSource.scheduled,
      };
}
