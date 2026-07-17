import 'package:injectable/injectable.dart';

import '../../../../core/error/result.dart';
import '../repositories/budget_repository.dart';

/// HU-10: closes a budget to history (stamps `archivedAt`). Not a delete — no
/// data is lost and it can be reactivated.
@injectable
class CloseBudget {
  const CloseBudget(this._repository);

  final BudgetRepository _repository;

  FutureResult<Unit> call(String id) => _repository.closeBudget(id);
}
