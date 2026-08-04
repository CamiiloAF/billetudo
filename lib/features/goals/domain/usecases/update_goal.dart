import 'package:injectable/injectable.dart';

import '../../../../core/error/result.dart';
import '../../../accounts/domain/repositories/account_repository.dart';
import '../entities/goal.dart';
import '../entities/goal_draft.dart';
import '../repositories/goal_repository.dart';

/// HU-08: edits a goal. Applies HU-02's account/currency rules — a new
/// account must exist and not be tombstoned; switching to an account of a
/// **different** currency is blocked once the goal already has movements
/// (mixing currencies would invalidate the history). `completedAt`/
/// `lastMilestonePct` reconciliation against a changed `targetMinor` (HU-07,
/// HU-06) is owned by `GoalRepositoryImpl.updateGoal`, since it needs the
/// derived `savedMinor` the repository already reads.
@injectable
class UpdateGoal {
  const UpdateGoal(this._repository, this._accounts);

  final GoalRepository _repository;
  final AccountRepository _accounts;

  FutureResult<Goal> call(GoalDraft draft) async {
    final id = draft.id;
    if (id == null) {
      return const Left(
        ValidationFailure(
          'cannot update a goal without an id',
          field: GoalDraft.fieldId,
        ),
      );
    }

    final validatedResult = draft.validated();
    if (validatedResult case Left(value: final failure)) {
      return Left(failure);
    }
    final normalized = validatedResult.getOrElse((_) => draft);

    final existingResult = await _repository.getGoal(id);
    if (existingResult case Left(value: final failure)) {
      return Left(failure);
    }
    final existing = existingResult.getOrElse((_) => throw StateError('unreachable'));

    final newAccountId = normalized.accountId;
    String currency;
    if (newAccountId != null) {
      final accountResult = await _accounts.getAccount(newAccountId);
      if (accountResult case Left(value: final failure)) {
        return Left(failure);
      }
      final account = accountResult.getOrElse((_) => throw StateError('unreachable'));

      final isChangingAccount = newAccountId != existing.accountId;
      final isChangingCurrency = account.currency != existing.currency;
      if (isChangingAccount && isChangingCurrency) {
        final hasMovementsResult = await _repository.hasContributions(id);
        if (hasMovementsResult case Left(value: final failure)) {
          return Left(failure);
        }
        final hasMovements = hasMovementsResult.getOrElse((_) => false);
        if (hasMovements) {
          return const Left(
            ValidationFailure(
              'changing to an account of a different currency is blocked '
              'once the goal has movements',
              field: GoalDraft.fieldCurrency,
            ),
          );
        }
      }
      currency = account.currency;
    } else {
      currency = normalized.currency;
    }

    return _repository.updateGoal(
      GoalDraft(
        id: id,
        name: normalized.name,
        targetMinor: normalized.targetMinor,
        currency: currency,
        accountId: newAccountId,
        targetDate: normalized.targetDate,
        icon: normalized.icon,
      ),
    );
  }
}
