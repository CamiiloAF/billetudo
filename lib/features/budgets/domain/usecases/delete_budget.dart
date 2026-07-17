import 'package:injectable/injectable.dart';

import '../../../../core/error/result.dart';
import '../repositories/budget_repository.dart';

/// HU-11: logical delete (stamps `deletedAt`, reversible trash). Budgets never
/// use `tombstonedAt` — nothing references `Budgets.id` by FK.
@injectable
class DeleteBudget {
  const DeleteBudget(this._repository);

  final BudgetRepository _repository;

  FutureResult<Unit> call(String id) => _repository.deleteBudget(id);
}
