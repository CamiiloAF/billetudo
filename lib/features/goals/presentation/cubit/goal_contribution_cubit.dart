import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import '../../../accounts/domain/entities/account_with_balance.dart';
import '../../../accounts/domain/usecases/watch_accounts.dart';
import '../../domain/entities/goal_contribution.dart';
import '../../domain/services/goal_category_seed.dart';
import '../../domain/usecases/contribute_to_goal.dart';
import '../../domain/usecases/withdraw_from_goal.dart';
import 'goal_contribution_state.dart';

/// Drives registrar-aporte/retiro (HU-03/HU-04): a tracking-only
/// [GoalContribution] row when the "¿Mover dinero de una cuenta?" toggle is
/// off, or a real transfer (account picker + optional presupuestable
/// category) when it is on.
@injectable
class GoalContributionCubit extends Cubit<GoalContributionState> {
  GoalContributionCubit(this._contribute, this._withdraw, this._watchAccounts)
      : super(
          GoalContributionState(
            goalId: '',
            goalName: '',
            direction: GoalMovementDirection.contribution,
            currency: 'COP',
            date: DateTime.now(),
          ),
        );

  final ContributeToGoal _contribute;
  final WithdrawFromGoal _withdraw;
  final WatchAccounts _watchAccounts;

  Future<void> start({
    required String goalId,
    required String goalName,
    required GoalMovementDirection direction,
    required String currency,
    int maxWithdrawableMinor = 0,
    bool hasLinkedAccount = true,
    int initialAmountMinor = 0,
  }) async {
    emit(
      GoalContributionState(
        goalId: goalId,
        goalName: goalName,
        direction: direction,
        currency: currency,
        maxWithdrawableMinor: maxWithdrawableMinor,
        amountMinor: initialAmountMinor,
        date: DateTime.now(),
        hasLinkedAccount: hasLinkedAccount,
      ),
    );
    final accounts = await _loadAccounts();
    if (isClosed) {
      return;
    }
    emit(state.copyWith(accounts: accounts));
  }

  Future<List<AccountWithBalance>> _loadAccounts() async {
    final result = await _watchAccounts().first;
    return result.fold((_) => const <AccountWithBalance>[], (list) => list);
  }

  void amountChanged(int amountMinor) =>
      emit(state.copyWith(amountMinor: amountMinor));

  void dateChanged(DateTime date) => emit(state.copyWith(date: date));

  void noteChanged(String note) => emit(state.copyWith(note: note));

  /// Caps the amount at the withdrawable maximum, for the "Usar todo" chip.
  void useMax() =>
      emit(state.copyWith(amountMinor: state.maxWithdrawableMinor));

  /// Flips "¿Mover dinero de una cuenta?". A no-op when trying to turn it on
  /// without a linked account ([GoalContributionState.hasLinkedAccount]).
  /// Turning it off clears the account/presupuesto/category selection, since
  /// they only apply to a money-moving movement.
  // ignore: avoid_positional_boolean_parameters
  void toggleMoveMoney(bool value) {
    if (value && !state.hasLinkedAccount) {
      return;
    }
    emit(
      state.copyWith(
        moveMoney: value,
        selectedAccountId: value ? null : () => null,
        countsInBudget: value && state.countsInBudget,
        categoryId: value && state.countsInBudget ? null : () => null,
      ),
    );
  }

  void selectAccount(String accountId) =>
      emit(state.copyWith(selectedAccountId: () => accountId));

  /// Flips "¿Incluir en tu presupuesto?". Turning it on defaults the category
  /// to the "Ahorros" seed (HU-03) when none was picked yet; turning it off
  /// clears the category, since a non-presupuestable movement carries none.
  // ignore: avoid_positional_boolean_parameters
  void toggleCountsInBudget(bool value) => emit(
        state.copyWith(
          countsInBudget: value,
          categoryId: () => value
              ? (state.categoryId ?? GoalCategorySeed.savingsCategoryId)
              : null,
        ),
      );

  void categoryChanged(String categoryId) =>
      emit(state.copyWith(categoryId: () => categoryId));

  Future<void> submit() async {
    if (!state.canSubmit) {
      return;
    }
    emit(
      state.copyWith(
          status: GoalContributionStatus.saving, failure: () => null),
    );

    final note = state.note.trim().isEmpty ? null : state.note.trim();
    final result = state.isWithdrawal
        ? await _withdraw(
            goalId: state.goalId,
            amountMinor: state.amountMinor,
            date: state.date,
            note: note,
            moveMoney: state.moveMoney,
            destinationAccountId: state.selectedAccountId,
            categoryId: state.categoryId,
            countsInBudget: state.countsInBudget,
          )
        : await _contribute(
            goalId: state.goalId,
            amountMinor: state.amountMinor,
            date: state.date,
            note: note,
            moveMoney: state.moveMoney,
            sourceAccountId: state.selectedAccountId,
            categoryId: state.categoryId,
            countsInBudget: state.countsInBudget,
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
