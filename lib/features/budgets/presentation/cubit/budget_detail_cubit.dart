import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/error/result.dart';
import '../../../transactions/domain/usecases/restore_transaction.dart';
import '../../domain/entities/budget_detail_data.dart';
import '../../domain/usecases/close_budget.dart';
import '../../domain/usecases/delete_budget.dart';
import '../../domain/usecases/get_budget_by_id.dart';
import '../../domain/usecases/get_budget_progress.dart';
import 'budget_detail_state.dart';

/// Drives the budget detail: reactive progress + activity for the selected
/// period, period navigation (HU-05) and the close/delete actions (HU-10/11).
@injectable
class BudgetDetailCubit extends Cubit<BudgetDetailState> {
  BudgetDetailCubit(
    this._getBudgetById,
    this._getBudgetProgress,
    this._closeBudget,
    this._deleteBudget,
    this._restoreTransaction,
  ) : super(const BudgetDetailState());

  final GetBudgetById _getBudgetById;
  final GetBudgetProgress _getBudgetProgress;
  final CloseBudget _closeBudget;
  final DeleteBudget _deleteBudget;
  final RestoreTransaction _restoreTransaction;

  StreamSubscription<Result<BudgetDetailData>>? _subscription;
  BudgetDetailData? _data;

  /// The selected period index; null follows the current period until the user
  /// steps away from it.
  int? _index;

  Future<void> start(String id) async {
    await _subscription?.cancel();
    emit(const BudgetDetailState());
    _index = null;
    _subscription = _getBudgetById(id).listen((result) {
      if (isClosed) {
        return;
      }
      result.fold(
        (failure) => emit(
          state.copyWith(
            status: BudgetDetailStatus.failure,
            failure: failure,
          ),
        ),
        _onData,
      );
    });
  }

  void _onData(BudgetDetailData data) {
    _data = data;
    _emitForIndex(resetActivity: false);
  }

  /// HU-05: step to the previous period, if any.
  void previousPeriod() {
    final view = state.view;
    if (view == null || !view.window.hasPrevious) {
      return;
    }
    _index = view.window.index - 1;
    _emitForIndex(resetActivity: true);
  }

  /// HU-05: step to the next period, if any.
  void nextPeriod() {
    final view = state.view;
    if (view == null || !view.window.hasNext) {
      return;
    }
    _index = view.window.index + 1;
    _emitForIndex(resetActivity: true);
  }

  /// HU-04: reveal one more page of the period's activity.
  void loadMoreActivity() => emit(
        state.copyWith(
          visibleActivityCount:
              state.visibleActivityCount + BudgetDetailState.activityPageSize,
        ),
      );

  /// HU-10: close to history.
  FutureResult<Unit> closeToHistory() {
    final id = _data?.budget.id;
    if (id == null) {
      return Future.value(const Right(unit));
    }
    return _closeBudget(id);
  }

  /// HU-11: move to trash.
  FutureResult<Unit> delete() {
    final id = _data?.budget.id;
    if (id == null) {
      return Future.value(const Right(unit));
    }
    return _deleteBudget(id);
  }

  /// HU-05: offers the "Deshacer" snackbar for a delete that happened in the
  /// transaction detail page opened from this budget's activity. The
  /// period's activity stream itself removes the row once `deletedAt` lands,
  /// so this only tracks the undo affordance.
  void notifyExternalDelete(String id) {
    if (isClosed) {
      return;
    }
    emit(state.copyWith(pendingUndoId: id));
  }

  /// HU-05: "Deshacer" from the snackbar.
  Future<void> undoDelete() async {
    final id = state.pendingUndoId;
    if (id == null) {
      return;
    }
    emit(state.copyWith(clearPendingUndo: true));
    await _restoreTransaction(id);
  }

  /// The snackbar timed out or the user dismissed it without undoing.
  void dismissUndo() {
    if (isClosed) {
      return;
    }
    emit(state.copyWith(clearPendingUndo: true));
  }

  void _emitForIndex({required bool resetActivity}) {
    final data = _data;
    if (data == null) {
      return;
    }
    final view = _getBudgetProgress(data, now: DateTime.now(), index: _index);
    // Keep the resolved index so navigation is relative to what is shown.
    _index = view.window.index;
    emit(
      state.copyWith(
        status: BudgetDetailStatus.ready,
        budget: data.budget,
        scope: data.scope,
        view: view,
        visibleActivityCount:
            resetActivity ? BudgetDetailState.activityPageSize : null,
      ),
    );
  }

  @override
  Future<void> close() async {
    await _subscription?.cancel();
    return super.close();
  }
}
