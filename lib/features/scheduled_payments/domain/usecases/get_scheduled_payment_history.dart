import 'package:injectable/injectable.dart';

import '../../../../core/error/result.dart';
import '../entities/scheduled_history_entry.dart';
import '../repositories/scheduled_payment_repository.dart';

/// HU-05: "Ver historial completo (N)" — loads more of a template's history
/// in place, without navigating away (criterion 13). Confirmed transactions
/// and skipped occurrences interleaved (page spec "Historial con omitidos").
@injectable
class GetScheduledPaymentHistory {
  const GetScheduledPaymentHistory(this._repository);

  final ScheduledPaymentRepository _repository;

  FutureResult<List<ScheduledHistoryEntry>> call(
    String scheduledPaymentId, {
    required int offset,
    required int limit,
  }) =>
      _repository.getScheduledPaymentHistory(
        scheduledPaymentId,
        offset: offset,
        limit: limit,
      );
}
