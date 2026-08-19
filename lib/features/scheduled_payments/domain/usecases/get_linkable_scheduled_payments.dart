import 'package:injectable/injectable.dart';

import '../../../../core/error/result.dart';
import '../entities/scheduled_payment_summary.dart';
import '../repositories/scheduled_payment_repository.dart';

/// HU-16 "Enlazar existente": active scheduled payment templates that are not
/// yet a debt's cuota nor another goal's recurring contribution, for the
/// picker sheet that lets a goal claim an already-created template instead of
/// duplicating it.
@injectable
class GetLinkableScheduledPayments {
  const GetLinkableScheduledPayments(this._repository);

  final ScheduledPaymentRepository _repository;

  Stream<Result<List<ScheduledPaymentSummary>>> call() =>
      _repository.watchLinkableScheduledPayments();
}
