import 'package:injectable/injectable.dart';

import '../../../../core/error/result.dart';
import '../repositories/budget_repository.dart';

/// HU-10: reactivates a closed budget (clears `archivedAt`).
@injectable
class ReactivateBudget {
  const ReactivateBudget(this._repository);

  final BudgetRepository _repository;

  FutureResult<Unit> call(String id) => _repository.reactivateBudget(id);
}
