import 'package:injectable/injectable.dart';

import '../../../../core/error/result.dart';
import '../../../accounts/domain/repositories/account_repository.dart';
import '../entities/goal.dart';
import '../entities/goal_draft.dart';
import '../repositories/goal_repository.dart';

/// HU-01/HU-02: validates and creates a goal. When [GoalDraft.accountId] is
/// set, the linked account must exist and not be tombstoned (HU-02), and the
/// goal's currency is forced to the account's currency, overriding whatever
/// the form's (now-locked) currency field carried.
@injectable
class CreateGoal {
  const CreateGoal(this._repository, this._accounts);

  final GoalRepository _repository;
  final AccountRepository _accounts;

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

    return _repository.createGoal(normalized);
  }
}
