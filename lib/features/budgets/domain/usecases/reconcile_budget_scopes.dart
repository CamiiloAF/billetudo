import 'package:injectable/injectable.dart';

import '../../../../core/error/result.dart';
import '../repositories/budget_repository.dart';

/// Fix #14: one-shot, idempotent reconciliation that un-freezes budgets whose
/// category scope was saved materialized ("Todas" as every id, a root as root +
/// all children) into the canonical form, so categories created afterwards are
/// counted. Ran when the budgets list opens (like the scheduled-payments
/// catch-up), which is the only place a frozen scope would be observed.
@injectable
class ReconcileBudgetScopes {
  const ReconcileBudgetScopes(this._repository);

  final BudgetRepository _repository;

  FutureResult<Unit> call() =>
      _repository.reconcileMaterializedCategoryScopes();
}
