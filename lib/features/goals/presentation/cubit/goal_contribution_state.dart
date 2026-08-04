import 'package:equatable/equatable.dart';

import '../../../../core/error/result.dart';
import '../../../accounts/domain/entities/account_with_balance.dart';
import '../../domain/entities/goal_contribution.dart';

enum GoalContributionStatus { ready, saving, saved, failure }

/// The registrar-aporte/retiro sheet state (HU-03/HU-04). The "¿Mover dinero
/// de una cuenta?" toggle (`ZgR6U`/`BETeo`/`GK69y`/`jFfBT`/`CpLy8`/`DiDwa`,
/// all approved in `billetudo.pen`) is fully interactive: turning it ON
/// reveals the account picker ([accounts]/[selectedAccountId]) and, once an
/// account is chosen, the "¿Incluir en tu presupuesto?" toggle
/// ([countsInBudget]) which in turn reveals the category picker
/// ([categoryId], defaulting to the "Ahorros" seed,
/// `GoalCategorySeed.savingsCategoryId`). `ContributeToGoal`/
/// `WithdrawFromGoal`/`GoalContributionDraft` already accept these fields and
/// write a real transfer (see their tests); [hasLinkedAccount] gates the
/// toggle itself — a goal with no linked account (HU-02) has nowhere to move
/// money into/from, so the toggle stays inert until the goal is edited.
class GoalContributionState extends Equatable {
  const GoalContributionState({
    required this.goalId,
    required this.goalName,
    required this.direction,
    required this.currency,
    this.maxWithdrawableMinor = 0,
    this.status = GoalContributionStatus.ready,
    this.amountMinor = 0,
    required this.date,
    this.note = '',
    this.milestoneCrossed,
    this.failure,
    this.hasLinkedAccount = true,
    this.moveMoney = false,
    this.accounts = const <AccountWithBalance>[],
    this.selectedAccountId,
    this.countsInBudget = false,
    this.categoryId,
  });

  final String goalId;
  final String goalName;
  final GoalMovementDirection direction;
  final String currency;

  /// HU-04's hard cap: a withdrawal can never exceed the goal's current
  /// derived `savedMinor`. Supplied by the caller (already known from the
  /// detail it opened from) so the sheet can bound the field without a
  /// second read.
  final int maxWithdrawableMinor;

  final GoalContributionStatus status;
  final int amountMinor;
  final DateTime date;
  final String note;

  /// HU-06: the single milestone threshold newly crossed by the last save,
  /// or `null` when none was. Read once by the page after `saved` to decide
  /// whether to open the celebration sheet/page.
  final int? milestoneCrossed;

  final Failure? failure;

  /// Whether the goal has a linked account (HU-02, `Goal.hasAccount`). When
  /// `false` the "¿Mover dinero de una cuenta?" toggle cannot be turned on:
  /// a contribution/withdrawal would have no goal-side account to move money
  /// into/from.
  final bool hasLinkedAccount;

  /// The "¿Mover dinero de una cuenta?" toggle.
  final bool moveMoney;

  /// The user's active accounts, loaded once when the sheet opens, to feed
  /// the "Cuenta de origen"/"Cuenta de destino" picker.
  final List<AccountWithBalance> accounts;

  /// The account picked as the *other* side of the transfer: origin for a
  /// contribution, destination for a withdrawal (the goal's own linked
  /// account is always resolved by the use case, never here).
  final String? selectedAccountId;

  /// The "¿Incluir en tu presupuesto?" toggle — only meaningful when
  /// [moveMoney] is `true`.
  final bool countsInBudget;

  /// Required only when [countsInBudget] is `true`.
  final String? categoryId;

  bool get isWithdrawal => direction == GoalMovementDirection.withdrawal;
  bool get isSaving => status == GoalContributionStatus.saving;

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

  bool get canSubmit =>
      amountMinor > 0 &&
      !isSaving &&
      (!isWithdrawal || amountMinor <= maxWithdrawableMinor) &&
      (!moveMoney || selectedAccountId != null) &&
      (!moveMoney || !countsInBudget || categoryId != null);

  GoalContributionState copyWith({
    GoalContributionStatus? status,
    int? amountMinor,
    DateTime? date,
    String? note,
    int? Function()? milestoneCrossed,
    Failure? Function()? failure,
    bool? moveMoney,
    List<AccountWithBalance>? accounts,
    String? Function()? selectedAccountId,
    bool? countsInBudget,
    String? Function()? categoryId,
  }) =>
      GoalContributionState(
        goalId: goalId,
        goalName: goalName,
        direction: direction,
        currency: currency,
        maxWithdrawableMinor: maxWithdrawableMinor,
        status: status ?? this.status,
        amountMinor: amountMinor ?? this.amountMinor,
        date: date ?? this.date,
        note: note ?? this.note,
        milestoneCrossed:
            milestoneCrossed == null ? this.milestoneCrossed : milestoneCrossed(),
        failure: failure == null ? this.failure : failure(),
        hasLinkedAccount: hasLinkedAccount,
        moveMoney: moveMoney ?? this.moveMoney,
        accounts: accounts ?? this.accounts,
        selectedAccountId: selectedAccountId == null
            ? this.selectedAccountId
            : selectedAccountId(),
        countsInBudget: countsInBudget ?? this.countsInBudget,
        categoryId: categoryId == null ? this.categoryId : categoryId(),
      );

  @override
  List<Object?> get props => [
        goalId,
        goalName,
        direction,
        currency,
        maxWithdrawableMinor,
        status,
        amountMinor,
        date,
        note,
        milestoneCrossed,
        failure,
        hasLinkedAccount,
        moveMoney,
        accounts,
        selectedAccountId,
        countsInBudget,
        categoryId,
      ];
}
