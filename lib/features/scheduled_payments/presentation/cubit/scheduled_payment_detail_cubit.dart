import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/error/result.dart';
import '../../../transactions/domain/usecases/restore_transaction.dart';
import '../../domain/entities/scheduled_payment_detail.dart';
import '../../domain/usecases/delete_scheduled_payment.dart';
import '../../domain/usecases/get_scheduled_payment_detail.dart';
import '../../domain/usecases/get_scheduled_payment_history.dart';
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
  ) : super(const ScheduledPaymentDetailState());

  final GetScheduledPaymentDetail _getScheduledPaymentDetail;
  final GetScheduledPaymentHistory _getScheduledPaymentHistory;
  final DeleteScheduledPayment _deleteScheduledPayment;
  final UndoSnoozeScheduledOccurrence _undoSnoozeOccurrence;
  final RestoreTransaction _restoreTransaction;

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
  /// occurrence, so the page can offer "Deshacer" (criterion 10).
  void notifySnoozed(String occurrenceId) =>
      emit(state.copyWith(pendingUndoSnoozeOccurrenceId: occurrenceId));

  Future<void> undoSnooze() async {
    final occurrenceId = state.pendingUndoSnoozeOccurrenceId;
    if (occurrenceId == null) {
      return;
    }
    emit(state.copyWith(clearPendingUndoSnooze: true));
    await _undoSnoozeOccurrence(occurrenceId);
  }

  void dismissUndoSnooze() =>
      emit(state.copyWith(clearPendingUndoSnooze: true));

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

  @override
  Future<void> close() async {
    await _subscription?.cancel();
    return super.close();
  }
}
