import 'package:injectable/injectable.dart';

import '../../../../core/error/result.dart';
import '../entities/scheduled_payment_summary.dart';
import '../repositories/scheduled_payment_repository.dart';

/// HU-04 overflow: reactive list of templates that no longer generate
/// occurrences, for the "Terminados" history screen.
@injectable
class GetFinishedScheduledPayments {
  const GetFinishedScheduledPayments(this._repository);

  final ScheduledPaymentRepository _repository;

  Stream<Result<List<ScheduledPaymentSummary>>> call() =>
      _repository.watchFinishedScheduledPayments();
}
