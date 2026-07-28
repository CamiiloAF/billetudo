import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/error/result.dart';
import '../../domain/entities/goal_detail.dart';
import '../../domain/entities/goal_quick_amount.dart';
import '../../domain/usecases/archive_goal.dart';
import '../../domain/usecases/contribute_to_goal.dart';
import '../../domain/usecases/create_goal_quick_amount.dart';
import '../../domain/usecases/delete_goal.dart';
import '../../domain/usecases/delete_goal_quick_amount.dart';
import '../../domain/usecases/watch_goal_detail.dart';
import '../../domain/usecases/watch_goal_quick_amounts.dart';
import 'goal_detail_state.dart';

/// Drives the goal detail (HU-05/06/07/12/15): the progress/projection/
/// momentum/history stream, the ledger peek-vs-expand toggle, the
/// archivar/eliminar actions (HU-09/HU-10), HU-14's one-tap quick amounts
/// (which reuse this same write path instead of opening the sheet), and the
/// custom "aporte rápido" chips (design-system/billetudo/pages/metas.md).
@injectable
class GoalDetailCubit extends Cubit<GoalDetailState> {
  GoalDetailCubit(
    this._watchGoalDetail,
    this._archiveGoal,
    this._deleteGoal,
    this._contributeToGoal,
    this._watchGoalQuickAmounts,
    this._createGoalQuickAmount,
    this._deleteGoalQuickAmount,
  ) : super(const GoalDetailState());

  final WatchGoalDetail _watchGoalDetail;
  final ArchiveGoal _archiveGoal;
  final DeleteGoal _deleteGoal;
  final ContributeToGoal _contributeToGoal;
  final WatchGoalQuickAmounts _watchGoalQuickAmounts;
  final CreateGoalQuickAmount _createGoalQuickAmount;
  final DeleteGoalQuickAmount _deleteGoalQuickAmount;

  StreamSubscription<Result<GoalDetail>>? _subscription;
  StreamSubscription<Result<List<GoalQuickAmount>>>? _quickAmountsSubscription;
  String? _goalId;

  /// Re-subscribes to the last loaded goal, for the error state's retry.
  Future<void> retry() async {
    final id = _goalId;
    if (id != null) {
      await start(id);
    }
  }

  Future<void> start(String goalId) async {
    _goalId = goalId;
    await _subscription?.cancel();
    await _quickAmountsSubscription?.cancel();
    emit(const GoalDetailState());
    _subscription = _watchGoalDetail(goalId).listen(_onDetail);
    _quickAmountsSubscription =
        _watchGoalQuickAmounts(goalId).listen(_onQuickAmounts);
  }

  void _onDetail(Result<GoalDetail> result) {
    if (isClosed) {
      return;
    }
    emit(
      result.fold(
        (failure) => state.copyWith(
          status: GoalDetailStatus.failure,
          failure: failure,
        ),
        (detail) => state.copyWith(
          status: GoalDetailStatus.ready,
          detail: () => detail,
        ),
      ),
    );
  }

  void _onQuickAmounts(Result<List<GoalQuickAmount>> result) {
    if (isClosed) {
      return;
    }
    // A failure here is not fatal to the whole detail screen — the row just
    // keeps showing whatever it last had (or the fixed chips alone).
    //
    // `copyWith`'s own `failure` parameter always overwrites (it does not
    // fall back to `this.failure` when omitted, unlike every other field),
    // so it must be passed explicitly here to avoid silently clearing a
    // `GoalDetailStatus.failure` set by the other subscription.
    result.fold((_) {}, (amounts) {
      emit(state.copyWith(quickAmounts: amounts, failure: state.failure));
    });
  }

  /// HU-05 `p6g6S`: expands the ledger peek in-place.
  void expandMovements() => emit(state.copyWith(movementsExpanded: true));

  /// HU-14: a one-tap quick amount reuses this exact write path — never a
  /// separate "quick" code path. Returns the milestone newly crossed
  /// (HU-06), or `null`.
  Future<Result<int?>> quickContribute(int amountMinor) async {
    final id = _goalId;
    if (id == null) {
      return const Left(ValidationFailure('no goal loaded'));
    }
    final result = await _contributeToGoal(
      goalId: id,
      amountMinor: amountMinor,
      date: DateTime.now(),
    );
    return result.map((movement) => movement.$2);
  }

  /// "+ Nueva": persists a new custom chip. Also reused as the write behind
  /// the "Deshacer" snackbar action after [deleteQuickAmount] — a simple
  /// re-insertion, not a restore of the deleted row.
  Future<Result<GoalQuickAmount>> createQuickAmount(int amountMinor) async {
    final id = _goalId;
    if (id == null) {
      return const Left(ValidationFailure('no goal loaded'));
    }
    return _createGoalQuickAmount(goalId: id, amountMinor: amountMinor);
  }

  /// Inline "x" on a custom chip: instant, real `DELETE`, no confirmation.
  Future<Result<Unit>> deleteQuickAmount(String id) =>
      _deleteGoalQuickAmount(id);

  /// HU-09.
  Future<Result<Unit>> archive() async {
    final id = _goalId;
    if (id == null) {
      return const Left(ValidationFailure('no goal loaded'));
    }
    return _archiveGoal(id);
  }

  /// HU-09.
  Future<Result<Unit>> unarchive() async {
    final id = _goalId;
    if (id == null) {
      return const Left(ValidationFailure('no goal loaded'));
    }
    return _archiveGoal.unarchive(id);
  }

  /// HU-10: soft delete (papelera). The page pops to the list on success.
  Future<Result<Unit>> delete() async {
    final id = _goalId;
    if (id == null) {
      return const Left(ValidationFailure('no goal loaded'));
    }
    return _deleteGoal(id);
  }

  @override
  Future<void> close() async {
    await _subscription?.cancel();
    await _quickAmountsSubscription?.cancel();
    return super.close();
  }
}
