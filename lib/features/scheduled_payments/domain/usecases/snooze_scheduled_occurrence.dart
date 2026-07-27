import 'package:injectable/injectable.dart';

import '../../../../core/error/result.dart';
import '../entities/snooze_outcome.dart';
import '../repositories/scheduled_payment_repository.dart';

/// HU-07: moves a single occurrence to a later date chosen by the user,
/// without affecting the balance or the template's cadence — the following
/// regular occurrence stays anchored to the original rhythm.
///
/// The minimum selectable date is `max(fecha original, hoy)` (criterion 10),
/// enforced here so no caller can bypass it. Reversible via
/// `UndoSnoozeScheduledOccurrence`.
@injectable
class SnoozeScheduledOccurrence {
  const SnoozeScheduledOccurrence(this._repository);

  final ScheduledPaymentRepository _repository;

  static const String fieldNewDate = 'newDate';

  FutureResult<SnoozeOutcome> call({
    required String scheduledPaymentId,
    required DateTime occurrenceDate,
    required DateTime newDate,
    DateTime? today,
  }) {
    final floor = _laterOf(occurrenceDate, today ?? DateTime.now());
    if (newDate.isBefore(_dateOnly(floor))) {
      return Future.value(
        const Left(
          ValidationFailure(
            'the new date cannot be before the original date or today',
            field: fieldNewDate,
          ),
        ),
      );
    }
    return _repository.snoozeOccurrence(
      scheduledPaymentId: scheduledPaymentId,
      occurrenceDate: occurrenceDate,
      newDate: newDate,
    );
  }

  DateTime _laterOf(DateTime a, DateTime b) =>
      _dateOnly(a).isAfter(_dateOnly(b)) ? _dateOnly(a) : _dateOnly(b);

  DateTime _dateOnly(DateTime value) =>
      DateTime(value.year, value.month, value.day);
}
