import 'package:injectable/injectable.dart';

import '../../../../core/error/result.dart';
import '../repositories/scheduled_payment_repository.dart';
import 'sync_scheduled_payment_reminders.dart';

/// HU-03: discards a pending occurrence without generating a transaction and
/// advances to the next one. Only reachable from within the confirmation
/// sheet/flow, never as a one-tap action on the list (criterion 9).
/// Reversible via `UndoSkipScheduledOccurrence`.
@injectable
class SkipScheduledOccurrence {
  const SkipScheduledOccurrence(this._repository, this._syncReminders);

  final ScheduledPaymentRepository _repository;
  final SyncScheduledPaymentReminders _syncReminders;

  /// Reconciles the reminder set afterwards (HU-08): resolving an occurrence
  /// changes which date the next reminder belongs to.
  FutureResult<Unit> call(String occurrenceId) async {
    final result = await _repository.skipOccurrence(occurrenceId);
    if (result.isRight()) {
      await _syncReminders();
    }
    return result;
  }
}
