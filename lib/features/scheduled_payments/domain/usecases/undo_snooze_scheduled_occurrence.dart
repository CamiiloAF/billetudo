import 'package:injectable/injectable.dart';

import '../../../../core/error/result.dart';
import '../repositories/scheduled_payment_repository.dart';

/// Undo for `SnoozeScheduledOccurrence`, from the "Deshacer" snackbar. Reverses
/// exactly one snooze step: it deletes a row the snooze materialized
/// (`wasCreated`), restores the immediately previous snoozed date
/// (`previousSnoozedToDate`) on a re-snooze, or clears the snooze back to
/// `pending` — see `ScheduledPaymentRepository.undoSnoozeOccurrence`.
@injectable
class UndoSnoozeScheduledOccurrence {
  const UndoSnoozeScheduledOccurrence(this._repository);

  final ScheduledPaymentRepository _repository;

  FutureResult<Unit> call(
    String occurrenceId, {
    required bool wasCreated,
    DateTime? previousSnoozedToDate,
  }) =>
      _repository.undoSnoozeOccurrence(
        occurrenceId,
        wasCreated: wasCreated,
        previousSnoozedToDate: previousSnoozedToDate,
      );
}
