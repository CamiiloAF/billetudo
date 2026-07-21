import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/error/result.dart';
import '../../domain/entities/pending_scheduled_occurrence.dart';
import '../../domain/usecases/get_pending_occurrences.dart';
import '../../domain/usecases/undo_skip_scheduled_occurrence.dart';
import '../../domain/usecases/undo_snooze_scheduled_occurrence.dart';
import 'pending_occurrences_state.dart';

/// Drives "Por confirmar" (HU-03/HU-04): the reactive list of every pending
/// occurrence, plus the "Deshacer" affordance for a skip/snooze that just
/// happened inside the confirmation sheet (criterion 9/10) — this cubit never
/// confirms/skips/snoozes itself, only surfaces the undo once the sheet
/// reports what happened.
@injectable
class PendingOccurrencesCubit extends Cubit<PendingOccurrencesState> {
  PendingOccurrencesCubit(
    this._getPendingOccurrences,
    this._undoSkipOccurrence,
    this._undoSnoozeOccurrence,
  ) : super(const PendingOccurrencesState());

  final GetPendingOccurrences _getPendingOccurrences;
  final UndoSkipScheduledOccurrence _undoSkipOccurrence;
  final UndoSnoozeScheduledOccurrence _undoSnoozeOccurrence;

  StreamSubscription<Result<List<PendingScheduledOccurrence>>>? _subscription;

  Future<void> start() async {
    await _subscription?.cancel();
    emit(const PendingOccurrencesState());
    _subscription = _getPendingOccurrences().listen(_onItems);
  }

  void _onItems(Result<List<PendingScheduledOccurrence>> result) {
    if (isClosed) {
      return;
    }
    emit(
      result.fold(
        (failure) => state.copyWith(
          status: PendingOccurrencesStatus.failure,
          failure: failure,
        ),
        (items) => state.copyWith(
            status: PendingOccurrencesStatus.ready, items: items),
      ),
    );
  }

  /// Called by the confirmation sheet's caller once it reports the occurrence
  /// was skipped, so the list page can offer "Deshacer".
  void notifySkipped(String occurrenceId) => emit(
        state.copyWith(
          pendingUndo: PendingOccurrenceUndo(
              occurrenceId: occurrenceId, isSnooze: false),
        ),
      );

  /// Same as [notifySkipped], for a snooze (criterion 10).
  /// [previousSnoozedToDate] is the row's snoozed date before this snooze, so
  /// the undo reverses exactly one step (a re-snooze steps back one date).
  void notifySnoozed(
    String occurrenceId, {
    DateTime? previousSnoozedToDate,
  }) =>
      emit(
        state.copyWith(
          pendingUndo: PendingOccurrenceUndo(
            occurrenceId: occurrenceId,
            isSnooze: true,
            previousSnoozedToDate: previousSnoozedToDate,
          ),
        ),
      );

  Future<void> undo() async {
    final pending = state.pendingUndo;
    if (pending == null) {
      return;
    }
    emit(state.copyWith(clearPendingUndo: true));
    if (pending.isSnooze) {
      // "Por confirmar" only ever snoozes already-materialized occurrences, so
      // the row is never created by the snooze (`wasCreated: false`).
      await _undoSnoozeOccurrence(
        pending.occurrenceId,
        wasCreated: false,
        previousSnoozedToDate: pending.previousSnoozedToDate,
      );
    } else {
      await _undoSkipOccurrence(pending.occurrenceId);
    }
  }

  void dismissUndo() => emit(state.copyWith(clearPendingUndo: true));

  @override
  Future<void> close() async {
    await _subscription?.cancel();
    return super.close();
  }
}
