import 'package:injectable/injectable.dart';

import '../../../../core/error/result.dart';
import '../repositories/scheduled_payment_repository.dart';

/// Replaces the full set of tags assigned to a template. Never called when
/// the template's `type` is `transfer` (criterion 16) — enforced by
/// `ScheduledPaymentDraft.validated`, which strips `tagIds` in that case;
/// this use case trusts its caller the same way
/// `SetTransactionTags` does.
@injectable
class SetScheduledPaymentTags {
  const SetScheduledPaymentTags(this._repository);

  final ScheduledPaymentRepository _repository;

  FutureResult<Unit> call(String scheduledPaymentId, List<String> tagIds) =>
      _repository.setScheduledPaymentTags(scheduledPaymentId, tagIds);
}
