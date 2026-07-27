import 'package:equatable/equatable.dart';

import 'scheduled_payment_occurrence.dart';

/// The result of `SnoozeScheduledOccurrence`, carrying not just the resulting
/// occurrence but the exact pre-snooze state needed to reverse *one* step
/// (HU-07's "Deshacer"): whether this snooze materialized a brand-new ledger
/// row ([wasCreated]) and, when it did not, the `snoozedToDate` the row held
/// immediately before this snooze ([previousSnoozedToDate]).
///
/// A second snooze of an already-snoozed occurrence must undo back to that
/// previous date, not to the original due date — the occurrence itself keeps
/// no history, so the pre-snooze state travels alongside it to the undo.
class SnoozeOutcome extends Equatable {
  const SnoozeOutcome({
    required this.occurrence,
    required this.wasCreated,
    this.previousSnoozedToDate,
  });

  final ScheduledPaymentOccurrence occurrence;

  /// True when the occurrence did not exist before and this snooze inserted it
  /// (the not-yet-due next occurrence, detail screen): undo removes the row.
  final bool wasCreated;

  /// The `snoozedToDate` the occurrence held right before this snooze, when it
  /// already existed. Null when [wasCreated], or when the occurrence was not
  /// snoozed before (a first snooze of a due `pending` occurrence): undo then
  /// clears `snoozedToDate` back to `pending`.
  final DateTime? previousSnoozedToDate;

  @override
  List<Object?> get props => [occurrence, wasCreated, previousSnoozedToDate];
}
