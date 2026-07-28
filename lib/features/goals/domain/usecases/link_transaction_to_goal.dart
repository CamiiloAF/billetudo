import 'package:injectable/injectable.dart';

import '../../../../core/error/result.dart';
import '../entities/goal_contribution.dart';
import '../repositories/goal_repository.dart';

/// HU-03 "Enlazar un movimiento existente": attributes a transaction the user
/// already registered to a goal, instead of duplicating it.
@injectable
class LinkTransactionToGoal {
  const LinkTransactionToGoal(this._repository);

  final GoalRepository _repository;

  FutureResult<GoalContribution> call({
    required String goalId,
    required String transactionId,
    required GoalMovementDirection direction,
    String? note,
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

    return _repository.linkExistingTransaction(
      goalId: goalId,
      transactionId: transactionId,
      direction: direction,
      note: note,
    );
  }
}
