import 'package:injectable/injectable.dart';

import '../../../../core/error/result.dart';
import '../repositories/scheduled_payment_repository.dart';
import 'sync_scheduled_payment_reminders.dart';

/// HU-02: catch-up run, meant to be called once when the app opens. Every
/// due date since the last run is processed exactly once — none lost, none
/// duplicated if the app closes mid-run (criterion 5) — either generating a
/// transaction (automatic mode) or accumulating a pending occurrence
/// (manual mode).
///
/// Also the app's reminder catch-up: the run advances `nextDate`, and Android
/// drops every scheduled alarm on reboot, so the reminder set is reconciled
/// afterwards ([SyncScheduledPaymentReminders]). That is what makes a device
/// that rebooted overnight wake up with its reminders back.
@injectable
class GenerateDueScheduledPayments {
  const GenerateDueScheduledPayments(this._repository, this._syncReminders);

  final ScheduledPaymentRepository _repository;
  final SyncScheduledPaymentReminders _syncReminders;

  FutureResult<Unit> call({DateTime? now}) async {
    final result = await _repository.generateDueScheduledPayments(
      now: now ?? DateTime.now(),
    );
    // Reconciles even on failure: a partial catch-up still may have moved a
    // cursor, and reconciling is idempotent.
    await _syncReminders();
    return result;
  }
}
