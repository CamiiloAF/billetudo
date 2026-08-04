import 'package:injectable/injectable.dart';

import '../../../../core/error/result.dart';
import '../../../accounts/domain/repositories/account_repository.dart';
import '../entities/goal.dart';
import '../entities/goal_draft.dart';
import '../repositories/goal_repository.dart';
import 'create_goal_quick_amount.dart';

/// HU-01/HU-02: validates and creates a goal. When [GoalDraft.accountId] is
/// set, the linked account must exist and not be tombstoned (HU-02), and the
/// goal's currency is forced to the account's currency, overriding whatever
/// the form's (now-locked) currency field carried.
///
/// On success, also seeds the two default "aporte rápido" chips
/// ($50.000/$100.000) as real `GoalQuickAmount` rows via
/// [CreateGoalQuickAmount], so the detail's quick-amount row is a single
/// uniform list of custom amounts — every chip, default or user-created,
/// carries the same delete ("x") affordance. This seeding only happens for
/// goals created after this change; there is no backfill for goals created
/// before it (no schema migration performs this insert retroactively).
@injectable
class CreateGoal {
  const CreateGoal(this._repository, this._accounts, this._createQuickAmount);

  final GoalRepository _repository;
  final AccountRepository _accounts;
  final CreateGoalQuickAmount _createQuickAmount;

  /// Default "aporte rápido" chip amounts seeded for every new goal, in
  /// cents ($50.000 and $100.000).
  static const List<int> _defaultQuickAmountsMinor = [5000000, 10000000];

  FutureResult<Goal> call(GoalDraft draft) async {
    final validatedResult = draft.validated(requireFutureTargetDate: true);
    if (validatedResult case Left(value: final failure)) {
      return Left(failure);
    }
    var normalized = validatedResult.getOrElse((_) => draft);

    final accountId = normalized.accountId;
    if (accountId != null) {
      final accountResult = await _accounts.getAccount(accountId);
      if (accountResult case Left(value: final failure)) {
        return Left(failure);
      }
      final account = accountResult.getOrElse((_) => throw StateError('unreachable'));
      normalized = GoalDraft(
        name: normalized.name,
        targetMinor: normalized.targetMinor,
        currency: account.currency,
        accountId: accountId,
        targetDate: normalized.targetDate,
        icon: normalized.icon,
        initialSavedMinor: normalized.initialSavedMinor,
      );
    }

    final createResult = await _repository.createGoal(normalized);
    if (createResult case Right(value: final goal)) {
      for (final amountMinor in _defaultQuickAmountsMinor) {
        await _createQuickAmount(goalId: goal.id, amountMinor: amountMinor);
      }
    }
    return createResult;
  }
}
