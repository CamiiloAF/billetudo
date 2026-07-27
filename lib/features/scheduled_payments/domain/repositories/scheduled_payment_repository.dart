import '../../../../core/error/result.dart';
import '../../../transactions/domain/entities/transaction.dart' as tx;
import '../entities/pending_scheduled_occurrence.dart';
import '../entities/scheduled_history_entry.dart';
import '../entities/scheduled_payment.dart';
import '../entities/scheduled_payment_detail.dart';
import '../entities/scheduled_payment_draft.dart';
import '../entities/scheduled_payment_summary.dart';
import '../entities/snooze_outcome.dart';
import '../entities/tag.dart';

/// Contract the Pagos Programados feature depends on. Implemented in `data/`
/// over Drift (source of truth).
///
/// Every write updates `updatedAt`. Deleting a template stamps `tombstonedAt`
/// (irreversible referential-integrity tombstone), never `deletedAt`:
/// `Transactions.scheduledPaymentId` keeps pointing at the row so already
/// generated transactions keep their historical link (criterion 12).
abstract class ScheduledPaymentRepository {
  /// HU-04: active templates ordered by `nextDate` ascending, enriched with
  /// display names. A template with a pending occurrence appears once, with
  /// `pendingOccurrenceCount` set, not repeated (criterion 11).
  Stream<Result<List<ScheduledPaymentSummary>>> watchActiveScheduledPayments();

  /// The "Terminados" history (HU-04 overflow, análogo al histórico de
  /// Presupuestos): templates that no longer generate occurrences — tombstoned,
  /// past `endDate`, or a `once` template already fired — ordered by
  /// `nextDate` descending (most recently finished first).
  Stream<Result<List<ScheduledPaymentSummary>>>
      watchFinishedScheduledPayments();

  /// HU-03/HU-04: pending occurrences across every manual-mode template,
  /// ordered by effective due date ascending.
  Stream<Result<List<PendingScheduledOccurrence>>> watchPendingOccurrences();

  /// HU-05: hybrid detail (template + next/pending occurrence + tags + first
  /// page of history). [historyPageSize] bounds the initial `history` page;
  /// call [getScheduledPaymentHistory] to load more (criterion 13).
  Stream<Result<ScheduledPaymentDetail>> watchScheduledPaymentDetail(
    String id, {
    int historyPageSize = 3,
  });

  /// Paginated "cargar más" for a template's history (criterion 13), most
  /// recent first — confirmed transactions and skipped occurrences interleaved
  /// (page spec "Historial con omitidos").
  FutureResult<List<ScheduledHistoryEntry>> getScheduledPaymentHistory(
    String scheduledPaymentId, {
    required int offset,
    required int limit,
  });

  FutureResult<ScheduledPayment> getScheduledPayment(String id);

  /// HU-01: persists a new template and its tags (never populated when
  /// `draft.type` is `transfer`, criterion 16).
  FutureResult<ScheduledPayment> createScheduledPayment(
    ScheduledPaymentDraft draft,
  );

  /// HU-05: edits a template. Never touches transactions already generated
  /// from it (criterion 12) — only affects occurrences not yet resolved.
  FutureResult<ScheduledPayment> updateScheduledPayment(
    ScheduledPaymentDraft draft,
  );

  /// HU-05: logical delete via `tombstonedAt` — stops future generation,
  /// preserves the historical reference on already-generated transactions.
  FutureResult<Unit> deleteScheduledPayment(String id);

  /// Replaces the full set of tags linked to [scheduledPaymentId] via
  /// `ScheduledPaymentTags` with [tagIds].
  FutureResult<Unit> setScheduledPaymentTags(
    String scheduledPaymentId,
    List<String> tagIds,
  );

  /// All tags, alphabetically ordered — feeds the tag picker on the template
  /// form. Same shared `Tags` table as Transacciones.
  Stream<Result<List<Tag>>> watchTags();

  /// A tag by (case-insensitive) name, if one already exists.
  FutureResult<Tag?> findTagByName(String name);

  /// Creates a new tag on the fly from the template form.
  FutureResult<Tag> createTag(String name);

  /// HU-02: catch-up run, meant to be called on app start. For every active
  /// template whose `nextDate` (and any subsequent occurrence still
  /// `<= now`, for repeating templates) is due:
  ///  - automatic mode (`requiresConfirmation == false`): generates a
  ///    `Transaction` (`source: scheduled`) per due date, copies the
  ///    template's tags onto it, and marks the occurrence `confirmed`.
  ///  - manual mode: creates one `pending` occurrence per due date (no
  ///    balance impact) instead.
  /// Advances the template's `nextDate` past every date it processed.
  /// Idempotent: an occurrence already recorded for a given date is never
  /// reprocessed, so an interrupted run cannot duplicate or drop one
  /// (criterion 5).
  FutureResult<Unit> generateDueScheduledPayments({required DateTime now});

  /// HU-03: applies a pending occurrence with the (possibly edited) final
  /// values from the confirmation sheet, stamping `source: scheduled` and
  /// `scheduledPaymentId` on the generated transaction. Never mutates the
  /// template itself (criterion 8).
  FutureResult<tx.Transaction> confirmOccurrence({
    required String occurrenceId,
    required DateTime date,
    required String accountId,
    required int amountMinor,
  });

  /// HU-03: discards a pending occurrence without generating a transaction.
  /// Reversible via [undoSkipOccurrence].
  FutureResult<Unit> skipOccurrence(String occurrenceId);

  /// Undo for [skipOccurrence] (the "Deshacer" snackbar): returns the
  /// occurrence to `pending`.
  FutureResult<Unit> undoSkipOccurrence(String occurrenceId);

  /// HU-07: moves a single occurrence to [newDate] without touching the
  /// template's cadence. Works both for an already-pending (vencida, manual
  /// mode) occurrence and for a template's next occurrence that has not
  /// become due yet (detail screen) — creating the ledger row on demand in
  /// the latter case. Returns a [SnoozeOutcome] carrying the resulting
  /// occurrence plus the pre-snooze state ([SnoozeOutcome.wasCreated],
  /// [SnoozeOutcome.previousSnoozedToDate]) the caller must hand back to
  /// [undoSnoozeOccurrence] so the "Deshacer" snackbar reverses exactly one
  /// step.
  FutureResult<SnoozeOutcome> snoozeOccurrence({
    required String scheduledPaymentId,
    required DateTime occurrenceDate,
    required DateTime newDate,
  });

  /// Undo for [snoozeOccurrence], reversing a single snooze step:
  ///  - [wasCreated] true: the snooze materialized the row, so delete it.
  ///  - [previousSnoozedToDate] non-null: restore that earlier snoozed date
  ///    (a re-snooze steps back one date, not to the original).
  ///  - both false/null: clear `snoozedToDate`, back to `pending`.
  FutureResult<Unit> undoSnoozeOccurrence(
    String occurrenceId, {
    required bool wasCreated,
    DateTime? previousSnoozedToDate,
  });

  /// HU-05 "Confirmar ahora": materializes a `pending` occurrence for a
  /// template's [scheduledPaymentId] on demand — any mode — without requiring
  /// `nextDate` to be due yet (`docs/bugfixes.md` point 1 — until now a
  /// template could only be confirmed/registered once its date had already
  /// passed). Only ever called explicitly from the detail screen's CTA, never
  /// from a `watch` — materializing a pending occurrence just because the
  /// detail screen is open would silently advance every template a user
  /// happens to look at.
  ///
  /// Idempotent alongside the catch-up generator and the due-date branch of
  /// [watchScheduledPaymentDetail]: if an awaiting occurrence already exists
  /// for this template, it is reused instead of duplicated. Fails with
  /// [ValidationFailure] when the template has nothing left to confirm (past
  /// `endDate`, tombstoned, or a `once` template already fired).
  FutureResult<PendingScheduledOccurrence> advanceScheduledOccurrence(
    String scheduledPaymentId,
  );

  /// Cleans up after "Confirmar ahora" when the user dismisses the confirmation
  /// sheet without acting: deletes the occurrence [advanceScheduledOccurrence]
  /// speculatively materialized, so merely opening and closing the sheet leaves
  /// no phantom pending and never moves the cursor. A no-op — and safe — when
  /// the occurrence was already confirmed/skipped/snoozed (the user acted) or
  /// when it is a genuine catch-up occurrence sitting before the cursor.
  FutureResult<Unit> discardUnconfirmedAdvanceOccurrence(String occurrenceId);
}
