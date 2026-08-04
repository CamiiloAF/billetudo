import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import '../../domain/entities/goal_contribution.dart';
import '../../domain/usecases/link_transaction_to_goal.dart';
import 'goal_link_state.dart';

/// Drives Movimientos link mode for Metas (HU-03 "Enlazar un movimiento"):
/// attributes an already-registered `Transaction` to the goal being linked,
/// without creating a new movement.
@injectable
class GoalLinkCubit extends Cubit<GoalLinkState> {
  GoalLinkCubit(this._linkTransactionToGoal)
      : super(
          const GoalLinkState(
            goalId: '',
            goalName: '',
            direction: GoalMovementDirection.contribution,
          ),
        );

  final LinkTransactionToGoal _linkTransactionToGoal;

  /// Seeds the mode with the goal the banner names and the movement
  /// direction the sheet was open on (contribution/withdrawal).
  void start({
    required String goalId,
    required String goalName,
    required GoalMovementDirection direction,
  }) =>
      emit(GoalLinkState(goalId: goalId, goalName: goalName, direction: direction));

  /// Links [transactionId] to the active goal. Returns `true` on success so
  /// the caller can pop back; emits a failure otherwise.
  Future<bool> link(String transactionId) async {
    if (state.status == GoalLinkStatus.linking) {
      return false;
    }
    emit(state.copyWith(status: GoalLinkStatus.linking, failure: () => null));
    final result = await _linkTransactionToGoal(
      goalId: state.goalId,
      transactionId: transactionId,
      direction: state.direction,
    );
    if (isClosed) {
      return false;
    }
    return result.fold(
      (failure) {
        emit(
          state.copyWith(status: GoalLinkStatus.failure, failure: () => failure),
        );
        return false;
      },
      (_) {
        emit(state.copyWith(status: GoalLinkStatus.idle));
        return true;
      },
    );
  }
}
