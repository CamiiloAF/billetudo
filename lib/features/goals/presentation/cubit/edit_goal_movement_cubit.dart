import 'package:clock/clock.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import '../../domain/entities/goal_contribution.dart';
import '../../domain/usecases/update_goal_movement.dart';
import 'edit_goal_movement_state.dart';

/// Drives the "Editar movimiento" sheet for a tracking-only [GoalContribution]
/// (`transactionId == null`): preloads monto/fecha/nota from the movement
/// being edited, then rewrites that SAME row through [UpdateGoalMovement] —
/// never creates or deletes anything.
@injectable
class EditGoalMovementCubit extends Cubit<EditGoalMovementState> {
  EditGoalMovementCubit(this._updateGoalMovement)
      : super(
          EditGoalMovementState(
            contributionId: '',
            goalId: '',
            goalName: '',
            direction: GoalMovementDirection.contribution,
            currency: 'COP',
            date: clock.now(),
          ),
        );

  final UpdateGoalMovement _updateGoalMovement;

  void start(
    GoalContribution movement, {
    required String goalName,
    required String currency,
  }) {
    emit(
      EditGoalMovementState(
        contributionId: movement.id,
        goalId: movement.goalId,
        goalName: goalName,
        direction: movement.direction,
        currency: currency,
        amountMinor: movement.amountMinor,
        date: movement.date,
        note: movement.note ?? '',
      ),
    );
  }

  void amountChanged(int amountMinor) =>
      emit(state.copyWith(amountMinor: amountMinor));

  void dateChanged(DateTime date) => emit(state.copyWith(date: date));

  void noteChanged(String note) => emit(state.copyWith(note: note));

  Future<void> submit() async {
    if (!state.canSubmit) {
      return;
    }
    emit(
      state.copyWith(
          status: EditGoalMovementStatus.saving, failure: () => null),
    );

    final note = state.note.trim().isEmpty ? null : state.note.trim();
    final result = await _updateGoalMovement(
      contributionId: state.contributionId,
      amountMinor: state.amountMinor,
      date: state.date,
      note: note,
    );
    if (isClosed) {
      return;
    }

    result.fold(
      (failure) => emit(
        state.copyWith(
          status: EditGoalMovementStatus.failure,
          failure: () => failure,
        ),
      ),
      (_) => emit(state.copyWith(status: EditGoalMovementStatus.saved)),
    );
  }
}
