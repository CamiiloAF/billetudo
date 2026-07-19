import 'package:injectable/injectable.dart';

import '../../../../core/error/result.dart';
import '../repositories/scheduled_payment_repository.dart';

/// Undo for `SnoozeScheduledOccurrence`, from the "Deshacer" snackbar: clears
/// `snoozedToDate` and returns the occurrence to `pending`.
@injectable
class UndoSnoozeScheduledOccurrence {
  const UndoSnoozeScheduledOccurrence(this._repository);

  final ScheduledPaymentRepository _repository;

  FutureResult<Unit> call(String occurrenceId) =>
      _repository.undoSnoozeOccurrence(occurrenceId);
}
