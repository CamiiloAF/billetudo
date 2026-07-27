import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/error/result.dart';
import '../../domain/usecases/snooze_scheduled_occurrence.dart';
import 'snooze_sheet_state.dart';

/// Drives the Posponer sheet (HU-07). Available both from the detail screen
/// (the next, not-yet-due occurrence) and from the confirmation sheet (an
/// already-pending, vencida occurrence in manual mode) — `start` takes
/// whichever occurrence date applies in each case.
@injectable
class SnoozeSheetCubit extends Cubit<SnoozeSheetState> {
  SnoozeSheetCubit(this._snoozeOccurrence)
      : super(
          SnoozeSheetState(
              minDate: DateTime.now(), selectedDate: DateTime.now()),
        );

  final SnoozeScheduledOccurrence _snoozeOccurrence;

  late String _scheduledPaymentId;
  late DateTime _occurrenceDate;

  /// Criterion 10 / HU-07: the floor is `max(fecha original, hoy)` and the new
  /// date must be strictly *after* it — posponer never moves a payment to the
  /// past, nor leaves it where it already is. So the first selectable day (and
  /// the default selection, which also decides the month the calendar opens
  /// on) is the day after that floor.
  void start({
    required String scheduledPaymentId,
    required DateTime occurrenceDate,
    DateTime? today,
  }) {
    _scheduledPaymentId = scheduledPaymentId;
    _occurrenceDate = occurrenceDate;
    final floor = _laterOf(occurrenceDate, today ?? DateTime.now());
    final firstSelectable = DateTime(floor.year, floor.month, floor.day + 1);
    emit(
      SnoozeSheetState(minDate: firstSelectable, selectedDate: firstSelectable),
    );
  }

  void dateSelected(DateTime date) => emit(state.copyWith(selectedDate: date));

  Future<void> save() async {
    emit(state.copyWith(status: SnoozeSheetStatus.saving));
    final result = await _snoozeOccurrence(
      scheduledPaymentId: _scheduledPaymentId,
      occurrenceDate: _occurrenceDate,
      newDate: state.selectedDate,
    );
    if (isClosed) {
      return;
    }
    switch (result) {
      case Left(value: final failure):
        emit(state.copyWith(
            status: SnoozeSheetStatus.failure, failure: failure));
      case Right(value: final outcome):
        emit(state.copyWith(status: SnoozeSheetStatus.saved, saved: outcome));
    }
  }

  DateTime _laterOf(DateTime a, DateTime b) =>
      _dateOnly(a).isAfter(_dateOnly(b)) ? _dateOnly(a) : _dateOnly(b);

  DateTime _dateOnly(DateTime value) =>
      DateTime(value.year, value.month, value.day);
}
