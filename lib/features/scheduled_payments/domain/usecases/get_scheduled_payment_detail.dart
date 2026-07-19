import 'package:injectable/injectable.dart';

import '../../../../core/error/result.dart';
import '../entities/scheduled_payment_detail.dart';
import '../repositories/scheduled_payment_repository.dart';

/// HU-05: reactive hybrid detail (template + next/pending occurrence +
/// tags + first page of generation history, criterion 13).
@injectable
class GetScheduledPaymentDetail {
  const GetScheduledPaymentDetail(this._repository);

  final ScheduledPaymentRepository _repository;

  Stream<Result<ScheduledPaymentDetail>> call(
    String id, {
    int historyPageSize = 3,
  }) =>
      _repository.watchScheduledPaymentDetail(
        id,
        historyPageSize: historyPageSize,
      );
}
