import 'package:injectable/injectable.dart';

import '../../../../core/error/result.dart';
import '../repositories/scheduled_payment_repository.dart';
import 'sync_scheduled_payment_reminders.dart';

/// Undo for `SkipScheduledOccurrence`, from the "Deshacer" snackbar: returns
/// the occurrence to `pending`.
@injectable
class UndoSkipScheduledOccurrence {
  const UndoSkipScheduledOccurrence(this._repository, this._syncReminders);

  final ScheduledPaymentRepository _repository;
  final SyncScheduledPaymentReminders _syncReminders;

  /// Reconciles the reminder set afterwards (HU-08): resolving an occurrence
  /// changes which date the next reminder belongs to.
  FutureResult<Unit> call(String occurrenceId) async {
    final result = await _repository.undoSkipOccurrence(occurrenceId);
    if (result.isRight()) {
      await _syncReminders();
    }
    return result;
  }
}
