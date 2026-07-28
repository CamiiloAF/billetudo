import 'package:injectable/injectable.dart';

import '../../../../core/error/result.dart';
import '../entities/goal_contribution.dart';
import '../entities/goal_contribution_draft.dart';
import '../repositories/goal_repository.dart';

/// HU-03: registers an aporte. Resolves the toggle "¿Mover dinero de una
/// cuenta?" into the fully-formed origin/destination pair the repository
/// needs (origin = the account the user picked, destination = the goal's
/// linked account) and rejects a movement against an archived goal.
@injectable
class ContributeToGoal {
  const ContributeToGoal(this._repository);

  final GoalRepository _repository;

  FutureResult<(GoalContribution, int?)> call({
    required String goalId,
    required int amountMinor,
    required DateTime date,
    String? note,
    bool moveMoney = false,
    String? sourceAccountId,
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
          'this goal has no linked account to move money into',
          field: GoalContributionDraft.fieldDestinationAccountId,
        ),
      );
    }

    final draftResult = GoalContributionDraft(
      goalId: goalId,
      amountMinor: amountMinor,
      direction: GoalMovementDirection.contribution,
      date: date,
      currency: goal.currency,
      note: note,
      moveMoney: moveMoney,
      originAccountId: moveMoney ? sourceAccountId : null,
      destinationAccountId: moveMoney ? goal.accountId : null,
      categoryId: categoryId,
      countsInBudget: moveMoney && countsInBudget,
    ).validated();
    if (draftResult case Left(value: final failure)) {
      return Left(failure);
    }

    return _repository.contribute(draftResult.getOrElse((_) => throw StateError('unreachable')));
  }
}
