import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/error/result.dart';
import '../../../transactions/domain/usecases/restore_transaction.dart';
import '../../domain/entities/scheduled_payment_detail.dart';
import '../../domain/usecases/advance_scheduled_occurrence.dart';
import '../../domain/usecases/delete_scheduled_payment.dart';
import '../../domain/usecases/discard_unconfirmed_advance_occurrence.dart';
import '../../domain/usecases/get_scheduled_payment_detail.dart';
import '../../domain/usecases/get_scheduled_payment_history.dart';
import '../../domain/usecases/skip_scheduled_occurrence.dart';
import '../../domain/usecases/undo_skip_scheduled_occurrence.dart';
import '../../domain/usecases/undo_snooze_scheduled_occurrence.dart';
import 'scheduled_payment_detail_state.dart';

/// Drives the template detail screen (HU-05/HU-07): the hybrid próximo pago +
/// configuración view, its in-place expandable history (criterion 13), and
/// the delete flow (criterion 12).
@injectable
class ScheduledPaymentDetailCubit extends Cubit<ScheduledPaymentDetailState> {
  ScheduledPaymentDetailCubit(
    this._getScheduledPaymentDetail,
    this._getScheduledPaymentHistory,
    this._deleteScheduledPayment,
    this._undoSnoozeOccurrence,
    this._restoreTransaction,
    this._advanceScheduledOccurrence,
    this._discardUnconfirmedAdvanceOccurrence,
    this._undoSkipOccurrence,
    this._skipOccurrence,
  ) : super(const ScheduledPaymentDetailState());

  final GetScheduledPaymentDetail _getScheduledPaymentDetail;
  final GetScheduledPaymentHistory _getScheduledPaymentHistory;
  final DeleteScheduledPayment _deleteScheduledPayment;
  final UndoSnoozeScheduledOccurrence _undoSnoozeOccurrence;
  final RestoreTransaction _restoreTransaction;
  final AdvanceScheduledOccurrence _advanceScheduledOccurrence;
  final DiscardUnconfirmedAdvanceOccurrence
      _discardUnconfirmedAdvanceOccurrence;
  final UndoSkipScheduledOccurrence _undoSkipOccurrence;
  final SkipScheduledOccurrence _skipOccurrence;

  StreamSubscription<Result<ScheduledPaymentDetail>>? _subscription;
  String? _id;

  Future<void> start(String id) async {
    _id = id;
    await _subscription?.cancel();
    emit(const ScheduledPaymentDetailState());
    _subscription = _getScheduledPaymentDetail(id).listen((result) {
      if (isClosed) {
        return;
      }
      emit(
        result.fold(
          (failure) => state.copyWith(
            status: ScheduledPaymentDetailStatus.failure,
            failure: failure,
          ),
          (detail) => state.copyWith(
            status: ScheduledPaymentDetailStatus.ready,
            detail: detail,
            // A fresh emission of the template resets the history window to
            // its first page unless the user had already expanded it.
            history: state.historyExpanded ? state.history : detail.history,
          ),
        ),
      );
    });
  }

  /// Criterion 13: "Ver historial completo (N)" — loads the next page
  /// in-place, no navigation.
  Future<void> loadMoreHistory({int pageSize = 10}) async {
    final id = _id;
    if (id == null || state.loadingMoreHistory || !state.hasMoreHistory) {
      return;
    }
    emit(state.copyWith(loadingMoreHistory: true, historyExpanded: true));
    final result = await _getScheduledPaymentHistory(
      id,
      offset: state.history.length,
      limit: pageSize,
    );
    if (isClosed) {
      return;
    }
    switch (result) {
      case Left(value: final failure):
        emit(state.copyWith(loadingMoreHistory: false, failure: failure));
      case Right(value: final more):
        emit(
          state.copyWith(
            history: [...state.history, ...more],
            loadingMoreHistory: false,
          ),
        );
    }
  }

  void requestDelete() => emit(state.copyWith(deletePrompt: true));

  void cancelDelete() => emit(state.copyWith(deletePrompt: false));

  /// Criterion 12: stops future generation while preserving the historical
  /// reference on transactions already generated.
  Future<void> confirmDelete() async {
    final id = _id;
    if (id == null) {
      return;
    }
    final result = await _deleteScheduledPayment(id);
    if (isClosed) {
      return;
    }
    switch (result) {
      case Left(value: final failure):
        emit(
          state.copyWith(
            status: ScheduledPaymentDetailStatus.failure,
            failure: failure,
            deletePrompt: false,
          ),
        );
      case Right():
        emit(
          state.copyWith(
            status: ScheduledPaymentDetailStatus.closed,
            deletePrompt: false,
          ),
        );
    }
  }

  /// Called after `SnoozeSheetCubit.save()` succeeds for this template's next
  /// occurrence, so the page can offer "Deshacer" (criterion 10). [wasCreated]
  /// and [previousSnoozedToDate] carry the pre-snooze state so the undo
  /// reverses exactly one step (a re-snooze steps back one date, not to the
  /// original).
  void notifySnoozed(
    String occurrenceId, {
    required bool wasCreated,
    DateTime? previousSnoozedToDate,
  }) =>
      emit(
        state.copyWith(
          pendingUndoSnoozeOccurrenceId: occurrenceId,
          pendingUndoSnoozeWasCreated: wasCreated,
          pendingUndoSnoozePreviousDate: previousSnoozedToDate,
        ),
      );

  Future<void> undoSnooze() async {
    final occurrenceId = state.pendingUndoSnoozeOccurrenceId;
    if (occurrenceId == null) {
      return;
    }
    final wasCreated = state.pendingUndoSnoozeWasCreated;
    final previousSnoozedToDate = state.pendingUndoSnoozePreviousDate;
    emit(state.copyWith(clearPendingUndoSnooze: true));
    await _undoSnoozeOccurrence(
      occurrenceId,
      wasCreated: wasCreated,
      previousSnoozedToDate: previousSnoozedToDate,
    );
  }

  void dismissUndoSnooze() {
    if (isClosed) {
      return;
    }
    emit(state.copyWith(clearPendingUndoSnooze: true));
  }

  /// Page spec "Recuperar" (Fase 2): a direct, reversible action on a skipped
  /// occurrence — returns it to `pending` (`undoSkipOccurrence`, no sheet). On
  /// success the page offers the "Pago recuperado · Deshacer" snackbar; the
  /// detail stream refreshes on its own (it watches the occurrences table), so
  /// the recovered row leaves the Historial. A failure stays silent here (the
  /// data layer already reported it): the confirm-now error copy would be
  /// misleading, and the row simply remains skipped.
  Future<void> recoverSkipped(String occurrenceId) async {
    final result = await _undoSkipOccurrence(occurrenceId);
    if (isClosed) {
      return;
    }
    if (result.isRight()) {
      emit(state.copyWith(pendingUndoRecoverOccurrenceId: occurrenceId));
    }
  }

  /// "Deshacer" from the "Pago recuperado" snackbar: re-skips the occurrence
  /// (`skipOccurrence`), same one-shot pattern as the snooze undo.
  Future<void> undoRecover() async {
    final occurrenceId = state.pendingUndoRecoverOccurrenceId;
    if (occurrenceId == null) {
      return;
    }
    emit(state.copyWith(clearPendingUndoRecover: true));
    await _skipOccurrence(occurrenceId);
  }

  /// The "Pago recuperado" snackbar timed out or was dismissed without undoing.
  void dismissUndoRecover() {
    if (isClosed) {
      return;
    }
    emit(state.copyWith(clearPendingUndoRecover: true));
  }

  /// HU-05: offers the "Deshacer" snackbar for a delete that happened in the
  /// transaction detail page opened from this template's history. The
  /// history stream itself removes the row once `deletedAt` lands, so this
  /// only tracks the undo affordance.
  void notifyExternalDelete(String id) {
    if (isClosed) {
      return;
    }
    emit(state.copyWith(pendingUndoDeleteTransactionId: id));
  }

  /// HU-05: "Deshacer" from the snackbar.
  Future<void> undoDelete() async {
    final id = state.pendingUndoDeleteTransactionId;
    if (id == null) {
      return;
    }
    emit(state.copyWith(clearPendingUndoDeleteTransaction: true));
    await _restoreTransaction(id);
  }

  /// The snackbar timed out or the user dismissed it without undoing.
  void dismissUndoDelete() {
    if (isClosed) {
      return;
    }
    emit(state.copyWith(clearPendingUndoDeleteTransaction: true));
  }

  /// HU-05 "Confirmar ahora" (`docs/bugfixes.md` point 1): materializes an
  /// automatic-mode template's next occurrence on demand, ahead of its
  /// `nextDate`, then hands it to the page so it can open the same mandatory
  /// `ConfirmationSheet` every other confirm path already funnels through —
  /// this never applies anything to the balance by itself.
  Future<void> confirmNow() async {
    final id = _id;
    if (id == null || state.confirmingNow) {
      return;
    }
    emit(state.copyWith(confirmingNow: true));
    final result = await _advanceScheduledOccurrence(scheduledPaymentId: id);
    if (isClosed) {
      return;
    }
    switch (result) {
      case Left(value: final failure):
        emit(
          state.copyWith(confirmingNow: false, failure: failure),
        );
      case Right(value: final pending):
        emit(
          state.copyWith(
            confirmingNow: false,
            confirmNowOccurrence: pending,
          ),
        );
    }
  }

  /// The page has closed the `ConfirmationSheet` opened for [confirmNow]'s
  /// result. Clears the one-shot trigger and, if the user dismissed the sheet
  /// without acting, discards the speculatively materialized occurrence so the
  /// next payment date never moves just from opening and closing the sheet.
  Future<void> dismissConfirmNow() async {
    final occurrenceId = state.confirmNowOccurrence?.occurrence.id;
    emit(state.copyWith(clearConfirmNowOccurrence: true));
    if (occurrenceId != null) {
      await _discardUnconfirmedAdvanceOccurrence(occurrenceId);
    }
  }

  @override
  Future<void> close() async {
    await _subscription?.cancel();
    return super.close();
  }
}
