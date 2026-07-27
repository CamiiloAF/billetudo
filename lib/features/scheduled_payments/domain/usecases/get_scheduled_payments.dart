import 'package:injectable/injectable.dart';

import '../../../../core/error/result.dart';
import '../entities/scheduled_payment_summary.dart';
import '../repositories/scheduled_payment_repository.dart';

/// HU-04: reactive list of active templates ordered by `nextDate` ascending,
/// for the "próximos vencimientos" screen.
@injectable
class GetScheduledPayments {
  const GetScheduledPayments(this._repository);

  final ScheduledPaymentRepository _repository;

  Stream<Result<List<ScheduledPaymentSummary>>> call() =>
      _repository.watchActiveScheduledPayments();
}
