import 'package:injectable/injectable.dart';

import '../../../../core/error/result.dart';
import '../repositories/scheduled_payment_repository.dart';

/// Undo for `SkipScheduledOccurrence`, from the "Deshacer" snackbar: returns
/// the occurrence to `pending`.
@injectable
class UndoSkipScheduledOccurrence {
  const UndoSkipScheduledOccurrence(this._repository);

  final ScheduledPaymentRepository _repository;

  FutureResult<Unit> call(String occurrenceId) =>
      _repository.undoSkipOccurrence(occurrenceId);
}
