import 'dart:async';

import 'package:clock/clock.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/error/result.dart';
import '../../../accounts/domain/entities/account_with_balance.dart';
import '../../../accounts/domain/usecases/watch_accounts.dart';
import '../../../categories/domain/entities/category.dart' show CategoryKind;
import '../../../scheduled_payments/domain/entities/scheduled_payment.dart';
import '../../../scheduled_payments/domain/entities/scheduled_payment_summary.dart';
import '../../domain/services/goal_category_seed.dart';
import '../../domain/usecases/create_goal_recurring_contribution.dart';
import '../../domain/usecases/get_linkable_scheduled_payments.dart';
import '../../domain/usecases/link_scheduled_payment_to_goal.dart';
import 'goal_recurring_contribution_state.dart';

/// Drives HU-16's "Aporte recurrente" flow: the config form for "Crear uno
/// nuevo" and the picker for "Enlazar un pago programado existente" — same
/// pattern as `GoalContributionCubit` sharing aportar/retirar in one cubit.
@injectable
class GoalRecurringContributionCubit
    extends Cubit<GoalRecurringContributionState> {
  GoalRecurringContributionCubit(
    this._watchAccounts,
    this._createGoalRecurringContribution,
    this._linkScheduledPaymentToGoal,
    this._getLinkableScheduledPayments,
  ) : super(
          GoalRecurringContributionState(
            goalId: '',
            goalName: '',
            currency: 'COP',
          ),
        );

  final WatchAccounts _watchAccounts;
  final CreateGoalRecurringContribution _createGoalRecurringContribution;
  final LinkScheduledPaymentToGoal _linkScheduledPaymentToGoal;
  final GetLinkableScheduledPayments _getLinkableScheduledPayments;

  StreamSubscription<Result<List<ScheduledPaymentSummary>>>?
      _linkableSubscription;

  /// Seeds the config form (create-new) with the goal, its currency, its
  /// active accounts and the "Ahorros" seed category preselected
  /// (`countsInBudget` defaults to `true`).
  Future<void> start({
    required String goalId,
    required String goalName,
    required String currency,
  }) async {
    emit(
      GoalRecurringContributionState(
        goalId: goalId,
        goalName: goalName,
        currency: currency,
        nextDate: clock.now(),
        categoryId: GoalCategorySeed.savingsCategoryId,
      ),
    );
    final accounts = await _loadAccounts();
    if (isClosed) {
      return;
    }
    emit(
      state.copyWith(
        status: GoalRecurringContributionStatus.ready,
        accounts: accounts,
        selectedAccountId: () =>
            accounts.isEmpty ? null : accounts.first.account.id,
      ),
    );
  }

  Future<List<AccountWithBalance>> _loadAccounts() async {
    final result = await _watchAccounts().first;
    return result.fold((_) => const <AccountWithBalance>[], (list) => list);
  }

  void accountSelected(String accountId) =>
      emit(state.copyWith(selectedAccountId: () => accountId));

  void amountChanged(int amountMinor) =>
      emit(state.copyWith(amountMinor: amountMinor));

  void frequencyChanged(ScheduledPaymentFrequency frequency) => emit(
        state.copyWith(
          frequency: frequency,
          interval:
              frequency == ScheduledPaymentFrequency.once ? 1 : state.interval,
        ),
      );

  void intervalChanged(int interval) =>
      emit(state.copyWith(interval: interval));

  void nextDateChanged(DateTime date) =>
      emit(state.copyWith(nextDate: date));

  /// Turning it on defaults the category to the "Ahorros" seed (same as
  /// `GoalContributionCubit.toggleCountsInBudget`) when none was picked yet;
  /// turning it off clears the category.
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

  /// "Crear uno nuevo": creates a brand-new template linked to the goal via
  /// `goalId`. Always an expense (a recurring contribution moves money out of
  /// the source account into savings).
  Future<void> submitCreate() async {
    if (!state.canSubmitCreate) {
      return;
    }
    emit(
      state.copyWith(
        status: GoalRecurringContributionStatus.saving,
        failure: () => null,
      ),
    );
    final result = await _createGoalRecurringContribution(
      goalId: state.goalId,
      accountId: state.selectedAccountId!,
      amountMinor: state.amountMinor,
      currency: state.currency,
      frequency: state.frequency,
      nextDate: state.nextDate,
      interval: state.interval,
      categoryId: state.countsInBudget ? state.categoryId : null,
      categoryKind: state.countsInBudget ? CategoryKind.expense : null,
    );
    if (isClosed) {
      return;
    }
    result.fold(
      (failure) => emit(
        state.copyWith(
          status: GoalRecurringContributionStatus.failure,
          failure: () => failure,
        ),
      ),
      (payment) => emit(
        state.copyWith(
          status: GoalRecurringContributionStatus.saved,
          createdScheduledPaymentId: () => payment.id,
        ),
      ),
    );
  }

  /// Loads (and keeps updated) the templates eligible for "Enlazar
  /// existente" — active, without a `debtId`/`goalId` yet.
  void watchLinkablePayments() {
    unawaited(_linkableSubscription?.cancel());
    _linkableSubscription = _getLinkableScheduledPayments().listen((result) {
      if (isClosed) {
        return;
      }
      result.fold(
        (_) {},
        (payments) => emit(
          state.copyWith(
            status: GoalRecurringContributionStatus.ready,
            linkablePayments: payments,
          ),
        ),
      );
    });
  }

  /// "Enlazar existente": attributes [scheduledPaymentId] to the goal instead
  /// of duplicating it.
  Future<bool> linkExisting(String scheduledPaymentId) async {
    if (state.isSaving) {
      return false;
    }
    emit(
      state.copyWith(
        status: GoalRecurringContributionStatus.saving,
        failure: () => null,
      ),
    );
    final result = await _linkScheduledPaymentToGoal(
      goalId: state.goalId,
      scheduledPaymentId: scheduledPaymentId,
    );
    if (isClosed) {
      return false;
    }
    return result.fold(
      (failure) {
        emit(
          state.copyWith(
            status: GoalRecurringContributionStatus.failure,
            failure: () => failure,
          ),
        );
        return false;
      },
      (payment) {
        emit(
          state.copyWith(
            status: GoalRecurringContributionStatus.saved,
            createdScheduledPaymentId: () => payment.id,
          ),
        );
        return true;
      },
    );
  }

  @override
  Future<void> close() {
    unawaited(_linkableSubscription?.cancel());
    return super.close();
  }
}
