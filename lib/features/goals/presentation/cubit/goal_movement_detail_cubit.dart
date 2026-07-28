import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/error/result.dart';
import '../../../transactions/domain/usecases/delete_transaction.dart';
import '../../domain/entities/goal_contribution.dart';
import '../../domain/usecases/get_goal_movement_accounts.dart';
import '../../domain/usecases/remove_goal_movement.dart';
import 'goal_movement_detail_state.dart';

/// Drives the movement detail sheet (`N8Dv2e`): resolves the origin/
/// destination account names for a money-moving movement, and deletes the
/// movement — through `DeleteTransaction` when it moved real money (so the
/// transfer and both account balances unwind together, cascading back here
/// via `GoalRepository.removeContributionForTransaction`), or through
/// `RemoveGoalMovement` for a tracking-only one.
@injectable
class GoalMovementDetailCubit extends Cubit<GoalMovementDetailState> {
  GoalMovementDetailCubit(
    this._getMovementAccounts,
    this._removeGoalMovement,
    this._deleteTransaction,
  ) : super(const GoalMovementDetailState());

  final GetGoalMovementAccounts _getMovementAccounts;
  final RemoveGoalMovement _removeGoalMovement;
  final DeleteTransaction _deleteTransaction;

  Future<void> start(GoalContribution movement) async {
    final transactionId = movement.transactionId;
    if (transactionId == null) {
      emit(const GoalMovementDetailState(status: GoalMovementDetailStatus.ready));
      return;
    }
    emit(const GoalMovementDetailState());
    final result = await _getMovementAccounts(transactionId);
    if (isClosed) {
      return;
    }
    emit(
      result.fold(
        (failure) => state.copyWith(
          status: GoalMovementDetailStatus.failure,
          failure: failure,
        ),
        (accounts) => state.copyWith(
          status: GoalMovementDetailStatus.ready,
          accounts: accounts,
        ),
      ),
    );
  }

  FutureResult<Unit> delete(GoalContribution movement) {
    final transactionId = movement.transactionId;
    return transactionId == null
        ? _removeGoalMovement(movement.id)
        : _deleteTransaction(transactionId);
  }
}
