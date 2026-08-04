import 'package:injectable/injectable.dart';

import '../../../../core/error/result.dart';
import '../entities/goal_movement_accounts.dart';
import '../repositories/goal_repository.dart';

/// The movement detail sheet's (`N8Dv2e`) "Cuenta de origen"/"Transferencia"
/// rows: resolves the two account names a money-moving movement touched.
@injectable
class GetGoalMovementAccounts {
  const GetGoalMovementAccounts(this._repository);

  final GoalRepository _repository;

  FutureResult<GoalMovementAccounts?> call(String transactionId) =>
      _repository.getMovementAccounts(transactionId);
}
