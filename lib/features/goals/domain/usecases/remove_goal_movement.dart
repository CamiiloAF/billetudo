import 'package:injectable/injectable.dart';

import '../../../../core/error/result.dart';
import '../repositories/goal_repository.dart';

/// The "Eliminar movimiento" sheets (`arr2T`/`H2ND7O`/`xCNxM`) for a
/// tracking-only movement (`transactionId == null`). A money-moving movement
/// is deleted through `DeleteTransaction` instead — see
/// `GoalRepository.removeContribution`'s doc.
@injectable
class RemoveGoalMovement {
  const RemoveGoalMovement(this._repository);

  final GoalRepository _repository;

  FutureResult<Unit> call(String contributionId) =>
      _repository.removeContribution(contributionId);
}
