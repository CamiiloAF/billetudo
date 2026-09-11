import 'package:injectable/injectable.dart';

import '../../../../core/error/result.dart';
import '../repositories/scheduled_payment_repository.dart';
import 'cancel_scheduled_payment_reminder.dart';
import 'sync_scheduled_payment_reminders.dart';

/// HU-05: deletes a template, stopping future generation while preserving
/// `scheduledPaymentId` as a historical reference on transactions already
/// generated from it.
///
/// Stamps `tombstonedAt`, never `deletedAt`: `Transactions.scheduledPaymentId`
/// references this row by foreign key (see `_SyncColumns.tombstonedAt`), so
/// this is the referential-integrity tombstone, not the reversible UX trash
/// — this feature offers no "restore a deleted template" flow.
///
/// Deleting also **cancels the template's reminder** (HU-08): a notification
/// that rings for a payment the user just deleted is the single fastest way
/// to teach someone to turn notifications off for good. The targeted cancel
/// runs first, then the full reconcile as a safety net.
@injectable
class DeleteScheduledPayment {
  const DeleteScheduledPayment(
    this._repository,
    this._cancelReminder,
    this._syncReminders,
  );

  final ScheduledPaymentRepository _repository;
  final CancelScheduledPaymentReminder _cancelReminder;
  final SyncScheduledPaymentReminders _syncReminders;

  FutureResult<Unit> call(String id) async {
    final result = await _repository.deleteScheduledPayment(id);
    if (result.isRight()) {
      await _cancelReminder(id);
      await _syncReminders();
    }
    return result;
  }
}
