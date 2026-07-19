import 'package:drift/drift.dart';

import '../../../../core/database/app_database.dart' as db;
import '../../domain/entities/scheduled_payment_occurrence.dart';

/// Translates between Drift's generated `ScheduledPaymentOccurrence` rows and
/// the domain [ScheduledPaymentOccurrence] entity — the idempotency ledger
/// for the catch-up generator (HU-02) and the confirm/skip/snooze actions
/// (HU-03/HU-07).
abstract final class ScheduledPaymentOccurrenceMapper {
  static ScheduledPaymentOccurrence toEntity(
    db.ScheduledPaymentOccurrence row,
  ) =>
      ScheduledPaymentOccurrence(
        id: row.id,
        scheduledPaymentId: row.scheduledPaymentId,
        occurrenceDate: row.occurrenceDate,
        status: _statusToDomain(row.status),
        snoozedToDate: row.snoozedToDate,
        generatedTransactionId: row.generatedTransactionId,
        createdAt: row.createdAt,
        updatedAt: row.updatedAt,
      );

  /// A `pending` occurrence created by the catch-up generator (manual mode)
  /// or by a proactive snooze from the detail screen.
  static db.ScheduledPaymentOccurrencesCompanion pendingInsertCompanion({
    required String scheduledPaymentId,
    required DateTime occurrenceDate,
    required DateTime now,
  }) =>
      db.ScheduledPaymentOccurrencesCompanion.insert(
        scheduledPaymentId: scheduledPaymentId,
        occurrenceDate: occurrenceDate,
        status: const Value(db.ScheduledOccurrenceStatus.pending),
        createdAt: Value(now),
        updatedAt: Value(now.millisecondsSinceEpoch),
      );

  /// A `confirmed` occurrence created directly by the catch-up generator in
  /// automatic mode (no `pending` stop-over).
  static db.ScheduledPaymentOccurrencesCompanion confirmedInsertCompanion({
    required String scheduledPaymentId,
    required DateTime occurrenceDate,
    required String generatedTransactionId,
    required DateTime now,
  }) =>
      db.ScheduledPaymentOccurrencesCompanion.insert(
        scheduledPaymentId: scheduledPaymentId,
        occurrenceDate: occurrenceDate,
        status: const Value(db.ScheduledOccurrenceStatus.confirmed),
        generatedTransactionId: Value(generatedTransactionId),
        createdAt: Value(now),
        updatedAt: Value(now.millisecondsSinceEpoch),
      );

  /// HU-03: applies a pending/snoozed occurrence.
  static db.ScheduledPaymentOccurrencesCompanion confirmCompanion({
    required String generatedTransactionId,
    required DateTime now,
  }) =>
      db.ScheduledPaymentOccurrencesCompanion(
        status: const Value(db.ScheduledOccurrenceStatus.confirmed),
        generatedTransactionId: Value(generatedTransactionId),
        updatedAt: Value(now.millisecondsSinceEpoch),
      );

  /// HU-03: discards a pending/snoozed occurrence.
  static db.ScheduledPaymentOccurrencesCompanion skipCompanion({
    required DateTime now,
  }) =>
      db.ScheduledPaymentOccurrencesCompanion(
        status: const Value(db.ScheduledOccurrenceStatus.skipped),
        updatedAt: Value(now.millisecondsSinceEpoch),
      );

  /// Undo for [skipCompanion]: returns to `pending`.
  static db.ScheduledPaymentOccurrencesCompanion undoSkipCompanion({
    required DateTime now,
  }) =>
      db.ScheduledPaymentOccurrencesCompanion(
        status: const Value(db.ScheduledOccurrenceStatus.pending),
        updatedAt: Value(now.millisecondsSinceEpoch),
      );

  /// HU-07: moves an existing occurrence to a later date.
  static db.ScheduledPaymentOccurrencesCompanion snoozeCompanion({
    required DateTime newDate,
    required DateTime now,
  }) =>
      db.ScheduledPaymentOccurrencesCompanion(
        status: const Value(db.ScheduledOccurrenceStatus.snoozed),
        snoozedToDate: Value(newDate),
        updatedAt: Value(now.millisecondsSinceEpoch),
      );

  /// A brand-new occurrence created purely to snooze a not-yet-due next
  /// payment (detail screen, criterion 10).
  static db.ScheduledPaymentOccurrencesCompanion snoozeInsertCompanion({
    required String scheduledPaymentId,
    required DateTime occurrenceDate,
    required DateTime newDate,
    required DateTime now,
  }) =>
      db.ScheduledPaymentOccurrencesCompanion.insert(
        scheduledPaymentId: scheduledPaymentId,
        occurrenceDate: occurrenceDate,
        status: const Value(db.ScheduledOccurrenceStatus.snoozed),
        snoozedToDate: Value(newDate),
        createdAt: Value(now),
        updatedAt: Value(now.millisecondsSinceEpoch),
      );

  /// Undo for [snoozeCompanion]/[snoozeInsertCompanion]: returns to
  /// `pending` and clears `snoozedToDate`.
  static db.ScheduledPaymentOccurrencesCompanion undoSnoozeCompanion({
    required DateTime now,
  }) =>
      db.ScheduledPaymentOccurrencesCompanion(
        status: const Value(db.ScheduledOccurrenceStatus.pending),
        snoozedToDate: const Value(null),
        updatedAt: Value(now.millisecondsSinceEpoch),
      );

  static ScheduledOccurrenceStatus _statusToDomain(
    db.ScheduledOccurrenceStatus status,
  ) =>
      switch (status) {
        db.ScheduledOccurrenceStatus.pending =>
          ScheduledOccurrenceStatus.pending,
        db.ScheduledOccurrenceStatus.confirmed =>
          ScheduledOccurrenceStatus.confirmed,
        db.ScheduledOccurrenceStatus.skipped =>
          ScheduledOccurrenceStatus.skipped,
        db.ScheduledOccurrenceStatus.snoozed =>
          ScheduledOccurrenceStatus.snoozed,
      };
}
