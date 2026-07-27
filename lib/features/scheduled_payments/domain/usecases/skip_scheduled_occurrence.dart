import 'package:injectable/injectable.dart';

import '../../../../core/error/result.dart';
import '../repositories/scheduled_payment_repository.dart';

/// HU-03: discards a pending occurrence without generating a transaction and
/// advances to the next one. Only reachable from within the confirmation
/// sheet/flow, never as a one-tap action on the list (criterion 9).
/// Reversible via `UndoSkipScheduledOccurrence`.
@injectable
class SkipScheduledOccurrence {
  const SkipScheduledOccurrence(this._repository);

  final ScheduledPaymentRepository _repository;

  FutureResult<Unit> call(String occurrenceId) =>
      _repository.skipOccurrence(occurrenceId);
}
