import 'package:injectable/injectable.dart';

import '../../../../core/error/result.dart';
import '../entities/scheduled_payment.dart';
import '../entities/scheduled_payment_draft.dart';
import '../repositories/scheduled_payment_repository.dart';

/// HU-05: edits a scheduled payment template. Never touches transactions
/// already generated from it (criterion 12) — only affects occurrences not
/// yet resolved (a not-yet-due `nextDate`, or a still-pending occurrence
/// that reads the template's current values, see
/// `PendingScheduledOccurrence`).
///
/// Same validation as `CreateScheduledPayment` via
/// [ScheduledPaymentDraft.validated].
@injectable
class UpdateScheduledPayment {
  const UpdateScheduledPayment(this._repository);

  final ScheduledPaymentRepository _repository;

  FutureResult<ScheduledPayment> call(ScheduledPaymentDraft draft) =>
      draft.validated().fold<FutureResult<ScheduledPayment>>(
            (failure) async => Left(failure),
            _repository.updateScheduledPayment,
          );
}
