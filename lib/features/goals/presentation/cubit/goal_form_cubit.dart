import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/error/result.dart';
import '../../../accounts/domain/entities/account_with_balance.dart';
import '../../../accounts/domain/usecases/watch_accounts.dart';
import '../../domain/entities/goal_draft.dart';
import '../../domain/usecases/create_goal.dart';
import '../../domain/usecases/delete_goal.dart';
import '../../domain/usecases/update_goal.dart';
import '../../domain/usecases/watch_goal_detail.dart';
import 'goal_form_state.dart';

/// Drives crear/editar meta (HU-01/HU-02/HU-08).
///
/// Parses what the user typed into a [GoalDraft] and hands it to
/// `CreateGoal`/`UpdateGoal`, which already own every validation rule
/// (`GoalDraft.validated()`) and the account/currency HU-02 rules — this
/// cubit only surfaces whatever field they reject.
@injectable
class GoalFormCubit extends Cubit<GoalFormState> {
  GoalFormCubit(
    this._createGoal,
    this._updateGoal,
    this._deleteGoal,
    this._watchGoalDetail,
    this._watchAccounts,
  ) : super(const GoalFormState());

  final CreateGoal _createGoal;
  final UpdateGoal _updateGoal;
  final DeleteGoal _deleteGoal;
  final WatchGoalDetail _watchGoalDetail;
  final WatchAccounts _watchAccounts;

  /// Loads the goal to edit, or prepares an empty form when [id] is null.
  Future<void> load(String? id) async {
    final accounts = await _loadAccounts();
    if (isClosed) {
      return;
    }

    if (id == null) {
      emit(GoalFormState(status: GoalFormStatus.ready, accounts: accounts));
      return;
    }

    final result = await _watchGoalDetail(id).first;
    if (isClosed) {
      return;
    }
    result.fold(
      (failure) => emit(
        state.copyWith(status: GoalFormStatus.failure, failure: () => failure),
      ),
      (detail) {
        final goal = detail.progress.goal;
        emit(
          GoalFormState(
            status: GoalFormStatus.ready,
            id: goal.id,
            name: goal.name,
            targetMinor: goal.targetMinor,
            currency: goal.currency,
            targetDate: goal.targetDate,
            icon: goal.icon,
            accountId: goal.accountId,
            accounts: accounts,
          ),
        );
      },
    );
  }

  Future<List<AccountWithBalance>> _loadAccounts() async {
    final result = await _watchAccounts().first;
    return result.fold((_) => const <AccountWithBalance>[], (list) => list);
  }

  void nameChanged(String name) => emit(
        state.copyWith(
          name: name,
          failedField:
              state.failedField == GoalDraft.fieldName ? () => null : null,
        ),
      );

  void targetMinorChanged(int targetMinor) => emit(
        state.copyWith(
          targetMinor: targetMinor,
          failedField: state.failedField == GoalDraft.fieldTargetMinor
              ? () => null
              : null,
        ),
      );

  void currencyChanged(String currency) => emit(state.copyWith(
        currency: currency,
        failedField: state.failedField == GoalDraft.fieldCurrency
            ? () => null
            : null,
      ));

  void targetDateChanged(DateTime? targetDate) => emit(
        state.copyWith(
          targetDate: () => targetDate,
          failedField:
              state.failedField == GoalDraft.fieldTargetDate ? () => null : null,
        ),
      );

  void iconChanged(String? icon) => emit(state.copyWith(icon: () => icon));

  /// HU-02: picking an account locks the currency to the account's own.
  void accountChanged(AccountWithBalance? account) => emit(
        state.copyWith(
          accountId: () => account?.account.id,
          currency: account?.account.currency ?? state.currency,
        ),
      );

  void initialSavedMinorChanged(int amountMinor) =>
      emit(state.copyWith(initialSavedMinor: amountMinor));

  Future<void> submit() async {
    if (state.isSaving) {
      return;
    }
    emit(
      state.copyWith(status: GoalFormStatus.saving, failedField: () => null),
    );

    final draft = GoalDraft(
      id: state.id,
      name: state.name,
      targetMinor: state.targetMinor,
      currency: state.currency,
      accountId: state.accountId,
      targetDate: state.targetDate,
      icon: state.icon,
      initialSavedMinor:
          state.isEditing || state.initialSavedMinor <= 0
              ? null
              : state.initialSavedMinor,
    );

    final result =
        state.isEditing ? await _updateGoal(draft) : await _createGoal(draft);
    if (isClosed) {
      return;
    }
    result.fold(
      (failure) => emit(
        state.copyWith(
          status: GoalFormStatus.ready,
          failedField: () =>
              failure is ValidationFailure ? failure.field : null,
          failure: () => failure,
        ),
      ),
      (_) => emit(state.copyWith(status: GoalFormStatus.saved)),
    );
  }

  /// HU-10: logical delete (papelera/undo) from the edit form.
  Future<void> delete() async {
    final id = state.id;
    if (id == null || state.isSaving) {
      return;
    }
    emit(state.copyWith(status: GoalFormStatus.saving));
    final result = await _deleteGoal(id);
    if (isClosed) {
      return;
    }
    result.fold(
      (failure) => emit(
        state.copyWith(status: GoalFormStatus.ready, failure: () => failure),
      ),
      (_) => emit(state.copyWith(status: GoalFormStatus.deleted)),
    );
  }
}
