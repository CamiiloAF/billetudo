import 'package:injectable/injectable.dart';

import '../../../../core/error/result.dart';
import '../entities/scheduled_payment.dart';
import '../entities/scheduled_payment_draft.dart';
import '../repositories/scheduled_payment_repository.dart';

/// HU-01: creates a scheduled payment template (one-time or repeating).
///
/// Validation (accountId required, positive `amountMinor`, transfer requires
/// a distinct destination account and forbids category/tags, category kind
/// matches the template's money direction) lives in
/// [ScheduledPaymentDraft.validated]; the repository only persists what
/// already passed it. No limit on the number of active templates.
@injectable
class CreateScheduledPayment {
  const CreateScheduledPayment(this._repository);

  final ScheduledPaymentRepository _repository;

  FutureResult<ScheduledPayment> call(ScheduledPaymentDraft draft) =>
      draft.validated().fold<FutureResult<ScheduledPayment>>(
            (failure) async => Left(failure),
            _repository.createScheduledPayment,
          );
}
