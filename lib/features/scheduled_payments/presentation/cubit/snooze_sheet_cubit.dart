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
          SnoozeSheetState(minDate: DateTime.now(), selectedDate: DateTime.now()),
        );

  final SnoozeScheduledOccurrence _snoozeOccurrence;

  late String _scheduledPaymentId;
  late DateTime _occurrenceDate;

  /// Criterion 10: the floor is `max(fecha original, hoy)`.
  void start({
    required String scheduledPaymentId,
    required DateTime occurrenceDate,
    DateTime? today,
  }) {
    _scheduledPaymentId = scheduledPaymentId;
    _occurrenceDate = occurrenceDate;
    final floor = _laterOf(occurrenceDate, today ?? DateTime.now());
    emit(SnoozeSheetState(minDate: floor, selectedDate: floor));
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
        emit(state.copyWith(status: SnoozeSheetStatus.failure, failure: failure));
      case Right(value: final occurrence):
        emit(state.copyWith(status: SnoozeSheetStatus.saved, saved: occurrence));
    }
  }

  DateTime _laterOf(DateTime a, DateTime b) =>
      _dateOnly(a).isAfter(_dateOnly(b)) ? _dateOnly(a) : _dateOnly(b);

  DateTime _dateOnly(DateTime value) =>
      DateTime(value.year, value.month, value.day);
}
