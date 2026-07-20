import 'package:equatable/equatable.dart';

/// Lifecycle of a single occurrence (one due date) of a scheduled payment
/// template, as opposed to the template itself. Mirrors
/// `ScheduledOccurrenceStatus`.
///
///  - `pending`: manual-confirmation template (HU-03), due date reached, not
///    yet applied to the balance.
///  - `confirmed`: applied — a transaction was generated (auto mode reaches
///    this directly; manual mode reaches it via user confirmation).
///  - `skipped`: the user discarded it (HU-03), no transaction generated.
///  - `snoozed`: the user moved only this occurrence to `snoozedToDate`
///    (HU-07); the template's cadence/`nextDate` stays untouched.
enum ScheduledOccurrenceStatus { pending, confirmed, skipped, snoozed }

/// A single due date of a `ScheduledPayment`, tracked so the catch-up
/// generator (HU-02) never generates the same date twice and never silently
/// loses one, and so confirm/skip/snooze (HU-03/HU-07) can act on it without
/// touching the template's own cadence.
///
/// Pure domain entity: no Drift types.
class ScheduledPaymentOccurrence extends Equatable {
  const ScheduledPaymentOccurrence({
    required this.id,
    required this.scheduledPaymentId,
    required this.occurrenceDate,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    this.snoozedToDate,
    this.generatedTransactionId,
  });

  final String id;
  final String scheduledPaymentId;

  /// The due date per the template's original cadence. Never mutated once
  /// created — see [effectiveDate] for the date to display/act on.
  final DateTime occurrenceDate;

  final ScheduledOccurrenceStatus status;

  /// Set only when [status] is `snoozed`: the later date the user chose
  /// (HU-07). Null for every other status.
  final DateTime? snoozedToDate;

  /// The transaction generated when this occurrence was confirmed (auto or
  /// manual mode). Null while `pending`, `skipped` or `snoozed`.
  final String? generatedTransactionId;

  final DateTime createdAt;

  /// Epoch millis, not a `DateTime` — see `_SyncColumns.updatedAt`.
  final int updatedAt;

  /// The date to display/act on: the snoozed date when present, the original
  /// due date otherwise (HU-07 — snoozing never mutates [occurrenceDate]).
  DateTime get effectiveDate => snoozedToDate ?? occurrenceDate;

  bool get isPending => status == ScheduledOccurrenceStatus.pending;

  /// Whether [date] counts as due — today or earlier, never a future date.
  /// The single rule for what counts as "pendiente para confirmar": both
  /// "Zona de pendientes" (list) and the detail's confirm affordance are
  /// gated on it, so a future occurrence (e.g. one snoozed forward past
  /// today) never surfaces as actionable early.
  static bool dateIsDueOn(DateTime date, DateTime now) {
    final today = DateTime(now.year, now.month, now.day);
    final normalized = DateTime(date.year, date.month, date.day);
    return !normalized.isAfter(today);
  }

  /// Same as [dateIsDueOn], applied to [effectiveDate].
  bool isDueOn(DateTime now) => dateIsDueOn(effectiveDate, now);

  @override
  List<Object?> get props => [
        id,
        scheduledPaymentId,
        occurrenceDate,
        status,
        snoozedToDate,
        generatedTransactionId,
        createdAt,
        updatedAt,
      ];
}
