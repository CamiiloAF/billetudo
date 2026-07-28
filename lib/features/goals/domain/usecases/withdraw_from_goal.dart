import 'package:injectable/injectable.dart';

import '../../../../core/error/result.dart';
import '../entities/goal_contribution.dart';
import '../entities/goal_contribution_draft.dart';
import '../repositories/goal_repository.dart';

/// HU-04: registers a retiro. Mirrors `ContributeToGoal` with origin/
/// destination swapped (origin = the goal's linked account, destination =
/// the account the user picked) and enforces the hard cap: a withdrawal can
/// never exceed the goal's current derived `savedMinor` (a real invariant,
/// not just a UI-side clamp).
@injectable
class WithdrawFromGoal {
  const WithdrawFromGoal(this._repository);

  final GoalRepository _repository;

  FutureResult<(GoalContribution, int?)> call({
    required String goalId,
    required int amountMinor,
    required DateTime date,
    String? note,
    bool moveMoney = false,
    String? destinationAccountId,
    String? categoryId,
    bool countsInBudget = false,
  }) async {
    final goalResult = await _repository.getGoal(goalId);
    if (goalResult case Left(value: final failure)) {
      return Left(failure);
    }
    final goal = goalResult.getOrElse((_) => throw StateError('unreachable'));

    if (goal.isArchived) {
      return const Left(
        ValidationFailure('an archived goal cannot receive new movements'),
      );
    }

    if (moveMoney && goal.accountId == null) {
      return const Left(
        ValidationFailure(
          'this goal has no linked account to move money from',
          field: GoalContributionDraft.fieldOriginAccountId,
        ),
      );
    }

    final savedResult = await _repository.getSavedMinor(goalId);
    if (savedResult case Left(value: final failure)) {
      return Left(failure);
    }
    final savedMinor = savedResult.getOrElse((_) => 0);
    if (amountMinor > savedMinor) {
      return const Left(
        ValidationFailure(
          'a withdrawal cannot exceed the goal\'s saved amount',
          field: GoalContributionDraft.fieldAmountMinor,
        ),
      );
    }

    final draftResult = GoalContributionDraft(
      goalId: goalId,
      amountMinor: amountMinor,
      direction: GoalMovementDirection.withdrawal,
      date: date,
      currency: goal.currency,
      note: note,
      moveMoney: moveMoney,
      originAccountId: moveMoney ? goal.accountId : null,
      destinationAccountId: moveMoney ? destinationAccountId : null,
      categoryId: categoryId,
      countsInBudget: moveMoney && countsInBudget,
    ).validated();
    if (draftResult case Left(value: final failure)) {
      return Left(failure);
    }

    return _repository.withdraw(draftResult.getOrElse((_) => throw StateError('unreachable')));
  }
}
