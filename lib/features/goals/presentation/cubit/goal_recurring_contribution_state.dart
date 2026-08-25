import 'package:clock/clock.dart';
import 'package:equatable/equatable.dart';

import '../../../../core/error/result.dart';
import '../../../accounts/domain/entities/account_with_balance.dart';
import '../../../scheduled_payments/domain/entities/scheduled_payment.dart';
import '../../../scheduled_payments/domain/entities/scheduled_payment_summary.dart';

enum GoalRecurringContributionStatus { loading, ready, saving, saved, failure }

/// The two entry points offered by the decision sheet (`HOdfO`/`XB4rS`,
/// HU-16): "Crear uno nuevo" opens the config form, "Enlazar un pago
/// programado existente" opens the picker. Purely presentation — never
/// persisted.
enum GoalRecurringContributionDecision { createNew, linkExisting }

/// Drives HU-16's "Aporte recurrente" flow for a goal: the config form (new
/// recurring template) and the picker (linking an existing one) share the
/// same cubit, same precedent as `GoalContributionCubit` sharing aportar and
/// retirar.
class GoalRecurringContributionState extends Equatable {
  GoalRecurringContributionState({
    required this.goalId,
    required this.goalName,
    required this.currency,
    this.status = GoalRecurringContributionStatus.loading,
    this.accounts = const <AccountWithBalance>[],
    this.selectedAccountId,
    this.amountMinor = 0,
    this.frequency = ScheduledPaymentFrequency.monthly,
    this.interval = 1,
    DateTime? nextDate,
    this.countsInBudget = true,
    this.categoryId,
    this.linkablePayments = const <ScheduledPaymentSummary>[],
    this.failure,
    this.createdScheduledPaymentId,
  }) : nextDate = nextDate ?? clock.now();

  final String goalId;
  final String goalName;
  final String currency;

  final GoalRecurringContributionStatus status;

  /// The user's active accounts, loaded once when the flow starts, for the
  /// "Cuenta de origen" picker.
  final List<AccountWithBalance> accounts;
  final String? selectedAccountId;

  final int amountMinor;
  final ScheduledPaymentFrequency frequency;
  final int interval;
  final DateTime nextDate;

  /// The "¿Incluir en tu presupuesto?" toggle (`ebcqG`'s `Q4XHHK`). Defaults
  /// to `true` with the "Ahorros" seed category preselected — a recurring
  /// contribution reads as a normal savings expense unless the user opts out.
  final bool countsInBudget;
  final String? categoryId;

  /// The active templates eligible to be linked (no `debtId`/`goalId` yet),
  /// loaded for the "Enlazar existente" picker.
  final List<ScheduledPaymentSummary> linkablePayments;

  final Failure? failure;

  /// Set once "Crear uno nuevo" succeeds, so the caller can close the form
  /// and hand the fresh template's id back.
  final String? createdScheduledPaymentId;

  bool get isSaving => status == GoalRecurringContributionStatus.saving;

  AccountWithBalance? get selectedAccount {
    final id = selectedAccountId;
    if (id == null) {
      return null;
    }
    for (final entry in accounts) {
      if (entry.account.id == id) {
        return entry;
      }
    }
    return null;
  }

  bool get canSubmitCreate =>
      amountMinor > 0 &&
      selectedAccountId != null &&
      !isSaving &&
      (!countsInBudget || categoryId != null);

  GoalRecurringContributionState copyWith({
    GoalRecurringContributionStatus? status,
    List<AccountWithBalance>? accounts,
    String? Function()? selectedAccountId,
    int? amountMinor,
    ScheduledPaymentFrequency? frequency,
    int? interval,
    DateTime? nextDate,
    bool? countsInBudget,
    String? Function()? categoryId,
    List<ScheduledPaymentSummary>? linkablePayments,
    Failure? Function()? failure,
    String? Function()? createdScheduledPaymentId,
  }) =>
      GoalRecurringContributionState(
        goalId: goalId,
        goalName: goalName,
        currency: currency,
        status: status ?? this.status,
        accounts: accounts ?? this.accounts,
        selectedAccountId: selectedAccountId == null
            ? this.selectedAccountId
            : selectedAccountId(),
        amountMinor: amountMinor ?? this.amountMinor,
        frequency: frequency ?? this.frequency,
        interval: interval ?? this.interval,
        nextDate: nextDate ?? this.nextDate,
        countsInBudget: countsInBudget ?? this.countsInBudget,
        categoryId: categoryId == null ? this.categoryId : categoryId(),
        linkablePayments: linkablePayments ?? this.linkablePayments,
        failure: failure == null ? this.failure : failure(),
        createdScheduledPaymentId: createdScheduledPaymentId == null
            ? this.createdScheduledPaymentId
            : createdScheduledPaymentId(),
      );

  @override
  List<Object?> get props => [
        goalId,
        goalName,
        currency,
        status,
        accounts,
        selectedAccountId,
        amountMinor,
        frequency,
        interval,
        nextDate,
        countsInBudget,
        categoryId,
        linkablePayments,
        failure,
        createdScheduledPaymentId,
      ];
}
