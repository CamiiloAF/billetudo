import 'package:injectable/injectable.dart';

import '../../../../core/error/result.dart';
import '../entities/pending_scheduled_occurrence.dart';
import '../repositories/scheduled_payment_repository.dart';

/// HU-05 "Confirmar ahora" (`docs/bugfixes.md` point 1): lets the user
/// register any template's next payment before its `nextDate` is due,
/// instead of only once it is overdue — automatic or manual mode alike.
///
/// Only materializes the `pending` occurrence the mandatory
/// `ConfirmScheduledOccurrence` flow then applies — it never itself moves
/// money, same "confirmation sheet is the only path that touches the
/// balance" invariant as the rest of HU-03.
@injectable
class AdvanceScheduledOccurrence {
  const AdvanceScheduledOccurrence(this._repository);

  final ScheduledPaymentRepository _repository;

  FutureResult<PendingScheduledOccurrence> call({
    required String scheduledPaymentId,
  }) {
    if (scheduledPaymentId.trim().isEmpty) {
      return Future.value(
        const Left(
          ValidationFailure(
            'a scheduled payment id is required',
            field: 'scheduledPaymentId',
          ),
        ),
      );
    }
    return _repository.advanceScheduledOccurrence(scheduledPaymentId);
  }
}
