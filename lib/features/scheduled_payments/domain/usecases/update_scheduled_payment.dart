import 'package:injectable/injectable.dart';

import '../../../../core/error/result.dart';
import '../entities/scheduled_payment.dart';
import '../entities/scheduled_payment_draft.dart';
import '../repositories/scheduled_payment_repository.dart';
import 'sync_scheduled_payment_reminders.dart';

/// HU-05: edits a scheduled payment template. Never touches transactions
/// already generated from it (criterion 12) — only affects occurrences not
/// yet resolved (a not-yet-due `nextDate`, or a still-pending occurrence
/// that reads the template's current values, see
/// `PendingScheduledOccurrence`).
///
/// Same validation as `CreateScheduledPayment` via
/// [ScheduledPaymentDraft.validated].
///
/// Changing the date, the reminder lead, or turning the reminder off must all
/// be reflected in what is actually pending on the device, so the reminder set
/// is reconciled after the write ([SyncScheduledPaymentReminders]).
@injectable
class UpdateScheduledPayment {
  const UpdateScheduledPayment(this._repository, this._syncReminders);

  final ScheduledPaymentRepository _repository;
  final SyncScheduledPaymentReminders _syncReminders;

  FutureResult<ScheduledPayment> call(ScheduledPaymentDraft draft) =>
      draft.validated().fold<FutureResult<ScheduledPayment>>(
        (failure) async => Left(failure),
        (validated) async {
          final result = await _repository.updateScheduledPayment(validated);
          if (result.isRight()) {
            await _syncReminders();
          }
          return result;
        },
      );
}
