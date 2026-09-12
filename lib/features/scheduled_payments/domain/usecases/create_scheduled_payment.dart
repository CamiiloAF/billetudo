import 'package:injectable/injectable.dart';

import '../../../../core/error/result.dart';
import '../entities/scheduled_payment.dart';
import '../entities/scheduled_payment_draft.dart';
import '../repositories/scheduled_payment_repository.dart';
import 'sync_scheduled_payment_reminders.dart';

/// HU-01: creates a scheduled payment template (one-time or repeating).
///
/// Validation (accountId required, positive `amountMinor`, transfer requires
/// a distinct destination account and forbids category/tags, category kind
/// matches the template's money direction) lives in
/// [ScheduledPaymentDraft.validated]; the repository only persists what
/// already passed it. No limit on the number of active templates.
///
/// After the write lands, the reminder set is reconciled
/// ([SyncScheduledPaymentReminders]): a notification must never outlive the
/// state that justified it. A failure there is deliberately swallowed — the
/// business write already succeeded, and a notification is a courtesy on top
/// of it, never a reason to fail a save.
@injectable
class CreateScheduledPayment {
  const CreateScheduledPayment(this._repository, this._syncReminders);

  final ScheduledPaymentRepository _repository;
  final SyncScheduledPaymentReminders _syncReminders;

  FutureResult<ScheduledPayment> call(ScheduledPaymentDraft draft) =>
      draft.validated().fold<FutureResult<ScheduledPayment>>(
        (failure) async => Left(failure),
        (validated) async {
          final result = await _repository.createScheduledPayment(validated);
          if (result.isRight()) {
            await _syncReminders();
          }
          return result;
        },
      );
}
