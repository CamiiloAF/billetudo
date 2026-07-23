import 'package:drift/drift.dart';

import '../../../../core/database/app_database.dart' as db;
import '../../domain/entities/scheduled_payment.dart';
import '../../domain/entities/scheduled_payment_draft.dart';

/// Translates between Drift's generated `ScheduledPayment` rows and the
/// domain [ScheduledPayment] entity. The only place where `*Data`/
/// `*Companion` types meet this feature's domain, so no generated type ever
/// escapes `data/`.
///
/// Enums are mapped explicitly (not by index) because they are stored as
/// text for parity with Postgres: the domain owns its own enum, matched by
/// meaning, not by declaration order.
abstract final class ScheduledPaymentMapper {
  static ScheduledPayment toEntity(db.ScheduledPayment row) => ScheduledPayment(
        id: row.id,
        accountId: row.accountId,
        categoryId: row.categoryId,
        amountMinor: row.amountMinor,
        currency: row.currency,
        type: typeToDomain(row.type),
        note: row.note,
        transferAccountId: row.transferAccountId,
        frequency: frequencyToDomain(row.frequency),
        interval: row.interval,
        firstPaymentDate: row.firstPaymentDate,
        nextDate: row.nextDate,
        endDate: row.endDate,
        requiresConfirmation: row.requiresConfirmation,
        createdAt: row.createdAt,
        updatedAt: row.updatedAt,
        tombstonedAt: row.tombstonedAt,
      );

  /// Insert companion. `id` is left to Drift's `clientDefault` (UUID).
  ///
  /// `firstPaymentDate` is fixed here to `draft.nextDate` — at creation time
  /// the date the user picked IS the first payment, so this is the one and
  /// only place that ever sets this column. [toUpdateCompanion] deliberately
  /// never touches it again: it is immutable after creation, unlike
  /// [db.ScheduledPaymentsCompanion.nextDate], which the catch-up generator
  /// (HU-02, see `nextDateCompanion`) keeps advancing.
  static db.ScheduledPaymentsCompanion toInsertCompanion(
    ScheduledPaymentDraft draft, {
    required DateTime now,
  }) =>
      db.ScheduledPaymentsCompanion.insert(
        accountId: draft.accountId,
        categoryId: Value(draft.categoryId),
        amountMinor: draft.amountMinor,
        currency: draft.currency,
        type: typeToDb(draft.type),
        note: Value(draft.note),
        transferAccountId: Value(draft.transferAccountId),
        frequency: frequencyToDb(draft.frequency),
        interval: Value(draft.interval),
        firstPaymentDate: draft.nextDate,
        nextDate: draft.nextDate,
        endDate: Value(draft.endDate),
        requiresConfirmation: Value(draft.requiresConfirmation),
        createdAt: Value(now),
        updatedAt: Value(now.millisecondsSinceEpoch),
      );

  /// Update companion (HU-05). Every nullable field is written explicitly
  /// (`Value(null)` rather than `absent()`) so clearing one in the form
  /// actually clears its old data instead of silently keeping it.
  ///
  /// `firstPaymentDate` (the "Primer pago" field the edit form binds to) is
  /// the schedule *anchor*, and its handling depends on WHO moved the date:
  /// the catch-up generator advances only [db.ScheduledPaymentsCompanion.nextDate]
  /// (via `nextDateCompanion`) and must NEVER touch the anchor — otherwise
  /// "Primer pago" would appear to drift on its own. An explicit user edit of
  /// the date, however, IS a re-anchor: it must persist to `firstPaymentDate`
  /// too, or the form (bound to `firstPaymentDate`) would keep showing the old
  /// date on re-open even though the next payment moved — item 18. The repo
  /// sets [rescheduleAnchor] only when it detected a real user date change, so
  /// this rewrites the anchor exclusively in that case; a normal edit (or the
  /// no-op resubmit of the untouched cursor) leaves it absent and untouched.
  static db.ScheduledPaymentsCompanion toUpdateCompanion(
    ScheduledPaymentDraft draft, {
    required DateTime now,
    bool rescheduleAnchor = false,
  }) =>
      db.ScheduledPaymentsCompanion(
        accountId: Value(draft.accountId),
        categoryId: Value(draft.categoryId),
        amountMinor: Value(draft.amountMinor),
        currency: Value(draft.currency),
        type: Value(typeToDb(draft.type)),
        note: Value(draft.note),
        transferAccountId: Value(draft.transferAccountId),
        frequency: Value(frequencyToDb(draft.frequency)),
        interval: Value(draft.interval),
        firstPaymentDate:
            rescheduleAnchor ? Value(draft.nextDate) : const Value.absent(),
        nextDate: Value(draft.nextDate),
        endDate: Value(draft.endDate),
        requiresConfirmation: Value(draft.requiresConfirmation),
        updatedAt: Value(now.millisecondsSinceEpoch),
      );

  /// HU-05: deleting a template. Stamps `tombstonedAt`, never `deletedAt` —
  /// `Transactions.scheduledPaymentId` references this row, so it must
  /// survive (see `_SyncColumns.tombstonedAt`).
  static db.ScheduledPaymentsCompanion tombstonedCompanion({
    required DateTime now,
  }) =>
      db.ScheduledPaymentsCompanion(
        tombstonedAt: Value(now),
        updatedAt: Value(now.millisecondsSinceEpoch),
      );

  /// HU-02: advances `nextDate` past every due date the catch-up generator
  /// processed for this template.
  static db.ScheduledPaymentsCompanion nextDateCompanion({
    required DateTime nextDate,
    required DateTime now,
  }) =>
      db.ScheduledPaymentsCompanion(
        nextDate: Value(nextDate),
        updatedAt: Value(now.millisecondsSinceEpoch),
      );

  static db.EntryType typeToDb(ScheduledPaymentType type) => switch (type) {
        ScheduledPaymentType.income => db.EntryType.income,
        ScheduledPaymentType.expense => db.EntryType.expense,
        ScheduledPaymentType.transfer => db.EntryType.transfer,
      };

  static ScheduledPaymentType typeToDomain(db.EntryType type) => switch (type) {
        db.EntryType.income => ScheduledPaymentType.income,
        db.EntryType.expense => ScheduledPaymentType.expense,
        db.EntryType.transfer => ScheduledPaymentType.transfer,
      };

  static db.ScheduleFrequency frequencyToDb(ScheduledPaymentFrequency freq) =>
      switch (freq) {
        ScheduledPaymentFrequency.once => db.ScheduleFrequency.once,
        ScheduledPaymentFrequency.daily => db.ScheduleFrequency.daily,
        ScheduledPaymentFrequency.weekly => db.ScheduleFrequency.weekly,
        ScheduledPaymentFrequency.monthly => db.ScheduleFrequency.monthly,
        ScheduledPaymentFrequency.yearly => db.ScheduleFrequency.yearly,
      };

  static ScheduledPaymentFrequency frequencyToDomain(
    db.ScheduleFrequency freq,
  ) =>
      switch (freq) {
        db.ScheduleFrequency.once => ScheduledPaymentFrequency.once,
        db.ScheduleFrequency.daily => ScheduledPaymentFrequency.daily,
        db.ScheduleFrequency.weekly => ScheduledPaymentFrequency.weekly,
        db.ScheduleFrequency.monthly => ScheduledPaymentFrequency.monthly,
        db.ScheduleFrequency.yearly => ScheduledPaymentFrequency.yearly,
      };
}
