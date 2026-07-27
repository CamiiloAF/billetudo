import 'package:injectable/injectable.dart';

import '../../../../core/error/result.dart';
import '../repositories/scheduled_payment_repository.dart';

/// Cleans up after "Confirmar ahora" (HU-05, `docs/bugfixes.md` point 1) when
/// the user dismisses the confirmation sheet without acting: removes the
/// occurrence that was speculatively materialized so the next payment date
/// never moves just from opening and closing the sheet. Safe no-op when the
/// user already confirmed/skipped/snoozed.
@injectable
class DiscardUnconfirmedAdvanceOccurrence {
  const DiscardUnconfirmedAdvanceOccurrence(this._repository);

  final ScheduledPaymentRepository _repository;

  FutureResult<Unit> call(String occurrenceId) =>
      _repository.discardUnconfirmedAdvanceOccurrence(occurrenceId);
}
