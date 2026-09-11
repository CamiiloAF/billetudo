import 'package:injectable/injectable.dart';

import '../../../../core/error/result.dart';
import '../repositories/scheduled_payment_repository.dart';
import 'sync_scheduled_payment_reminders.dart';

/// Undo for `SnoozeScheduledOccurrence`, from the "Deshacer" snackbar. Reverses
/// exactly one snooze step: it deletes a row the snooze materialized
/// (`wasCreated`), restores the immediately previous snoozed date
/// (`previousSnoozedToDate`) on a re-snooze, or clears the snooze back to
/// `pending` — see `ScheduledPaymentRepository.undoSnoozeOccurrence`.
@injectable
class UndoSnoozeScheduledOccurrence {
  const UndoSnoozeScheduledOccurrence(this._repository, this._syncReminders);

  final ScheduledPaymentRepository _repository;
  final SyncScheduledPaymentReminders _syncReminders;

  /// Reconciles the reminder set afterwards (HU-08): undoing a snooze puts the
  /// due date back, and the reminder has to follow it back too.
  FutureResult<Unit> call(
    String occurrenceId, {
    required bool wasCreated,
    DateTime? previousSnoozedToDate,
  }) async {
    final result = await _repository.undoSnoozeOccurrence(
      occurrenceId,
      wasCreated: wasCreated,
      previousSnoozedToDate: previousSnoozedToDate,
    );
    if (result.isRight()) {
      await _syncReminders();
    }
    return result;
  }
}
