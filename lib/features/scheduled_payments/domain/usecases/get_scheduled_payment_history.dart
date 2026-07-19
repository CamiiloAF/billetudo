import 'package:injectable/injectable.dart';

import '../../../../core/error/result.dart';
import '../../../transactions/domain/entities/transaction.dart' as tx;
import '../repositories/scheduled_payment_repository.dart';

/// HU-05: "Ver historial completo (N)" — loads more of a template's
/// generated transactions in place, without navigating away (criterion 13).
@injectable
class GetScheduledPaymentHistory {
  const GetScheduledPaymentHistory(this._repository);

  final ScheduledPaymentRepository _repository;

  FutureResult<List<tx.Transaction>> call(
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
