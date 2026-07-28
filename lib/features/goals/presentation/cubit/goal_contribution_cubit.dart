import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import '../../domain/entities/goal_contribution.dart';
import '../../domain/usecases/contribute_to_goal.dart';
import '../../domain/usecases/withdraw_from_goal.dart';
import 'goal_contribution_state.dart';

/// Drives registrar-aporte/retiro (HU-03/HU-04). Tracking-only for now (no
/// "¿Mover dinero de una cuenta?" toggle — see [GoalContributionState]'s doc):
/// every save writes a plain [GoalMovementDirection] row, never a transfer.
@injectable
class GoalContributionCubit extends Cubit<GoalContributionState> {
  GoalContributionCubit(this._contribute, this._withdraw)
      : super(
          GoalContributionState(
            goalId: '',
            direction: GoalMovementDirection.contribution,
            currency: 'COP',
            date: DateTime.now(),
          ),
        );

  final ContributeToGoal _contribute;
  final WithdrawFromGoal _withdraw;

  void start({
    required String goalId,
    required GoalMovementDirection direction,
    required String currency,
    int maxWithdrawableMinor = 0,
  }) =>
      emit(
        GoalContributionState(
          goalId: goalId,
          direction: direction,
          currency: currency,
          maxWithdrawableMinor: maxWithdrawableMinor,
          date: DateTime.now(),
        ),
      );

  void amountChanged(int amountMinor) =>
      emit(state.copyWith(amountMinor: amountMinor));

  void dateChanged(DateTime date) => emit(state.copyWith(date: date));

  void noteChanged(String note) => emit(state.copyWith(note: note));

  /// Caps the amount at the withdrawable maximum, for the "Usar todo" chip.
  void useMax() => emit(state.copyWith(amountMinor: state.maxWithdrawableMinor));

  Future<void> submit() async {
    if (!state.canSubmit) {
      return;
    }
    emit(
      state.copyWith(status: GoalContributionStatus.saving, failure: () => null),
    );

    final note = state.note.trim().isEmpty ? null : state.note.trim();
    final result = state.isWithdrawal
        ? await _withdraw(
            goalId: state.goalId,
            amountMinor: state.amountMinor,
            date: state.date,
            note: note,
          )
        : await _contribute(
            goalId: state.goalId,
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
          status: GoalContributionStatus.failure,
          failure: () => failure,
        ),
      ),
      (movement) => emit(
        state.copyWith(
          status: GoalContributionStatus.saved,
          milestoneCrossed: () => movement.$2,
        ),
      ),
    );
  }
}
