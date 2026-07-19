import 'package:injectable/injectable.dart';

import '../../../../core/error/result.dart';
import '../../../transactions/domain/entities/transaction.dart' as tx;
import '../repositories/scheduled_payment_repository.dart';

/// HU-03: applies a pending occurrence with the final (possibly edited)
/// values from the mandatory confirmation sheet (criterion 7) — there is no
/// path that applies an occurrence without going through it, not even from
/// the guided review.
///
/// Editing `date`/`accountId`/`amountMinor` here only affects this one
/// occurrence: it never rewrites the template (criterion 8), so the next
/// occurrence proposes the template's original values again.
@injectable
class ConfirmScheduledOccurrence {
  const ConfirmScheduledOccurrence(this._repository);

  final ScheduledPaymentRepository _repository;

  FutureResult<tx.Transaction> call({
    required String occurrenceId,
    required DateTime date,
    required String accountId,
    required int amountMinor,
  }) {
    if (amountMinor <= 0) {
      return Future.value(
        const Left(
          ValidationFailure(
            'the amount must be a positive integer of cents',
            field: 'amountMinor',
          ),
        ),
      );
    }
    if (accountId.trim().isEmpty) {
      return Future.value(
        const Left(
          ValidationFailure('an account is required', field: 'accountId'),
        ),
      );
    }
    return _repository.confirmOccurrence(
      occurrenceId: occurrenceId,
      date: date,
      accountId: accountId,
      amountMinor: amountMinor,
    );
  }
}
