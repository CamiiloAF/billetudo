import '../../../../core/l10n/gen/app_localizations.dart';
import '../../domain/entities/goal_contribution.dart';
import '../../domain/entities/goal_movement_accounts.dart';
import 'goal_format.dart';

/// The exact title/message copy of the "Eliminar movimiento" sheets
/// (`arr2T`/`H2ND7O`/`xCNxM`): three variants depending on whether the
/// movement moved real money, was a tracking-only entry, and whether
/// deleting it would revert an already-completed goal back to in-progress.
/// Kept a pure formatter (never a `Widget`), same precedent as `GoalFormat`.
abstract final class GoalMovementDeleteCopy {
  const GoalMovementDeleteCopy._();

  static ({String title, String message}) build(
    AppLocalizations l10n, {
    required GoalContribution movement,
    required String currency,
    required String goalName,
    required bool goalCompleted,
    GoalMovementAccounts? accounts,
  }) {
    final kind = movement.direction == GoalMovementDirection.withdrawal
        ? l10n.goalMovementKindWithdrawalLower
        : l10n.goalMovementKindContributionLower;
    final amount = GoalFormat.amount(movement.amountMinor, currency);
    final title = l10n.goalDeleteMovementTitle(kind, amount);
    final isTransfer = movement.movedMoney && accounts != null;

    final message = goalCompleted
        ? (isTransfer
            ? l10n.goalDeleteMovementMessageCompletedTransfer(
                kind,
                goalName,
                accounts.originName,
                accounts.destinationName,
              )
            : l10n.goalDeleteMovementMessageCompletedManual(kind, goalName))
        : (isTransfer
            ? l10n.goalDeleteMovementMessageTransfer(
                accounts.originName,
                accounts.destinationName,
              )
            : l10n.goalDeleteMovementMessageManual(kind));

    return (title: title, message: message);
  }
}
