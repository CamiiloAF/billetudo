import 'package:injectable/injectable.dart';

import '../../../../core/error/result.dart';
import '../entities/pending_scheduled_occurrence.dart';
import '../repositories/scheduled_payment_repository.dart';

/// HU-03/HU-04: reactive list of pending occurrences across every
/// manual-mode template, ordered by effective due date ascending, for the
/// "Por confirmar" subpantalla.
@injectable
class GetPendingOccurrences {
  const GetPendingOccurrences(this._repository);

  final ScheduledPaymentRepository _repository;

  Stream<Result<List<PendingScheduledOccurrence>>> call() =>
      _repository.watchPendingOccurrences();
}
