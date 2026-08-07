import 'package:injectable/injectable.dart';

import '../../../../core/error/result.dart';
import '../repositories/budget_repository.dart';

/// One-shot count of active budgets (neither closed nor trashed). Used by
/// `BudgetFormCubit` right after a successful creation to detect "this was
/// the user's *second* active budget" — the moment the "¿cuál se destaca en
/// Inicio?" minitutorial fires (`design-system/billetudo/pages/
/// presupuestos.md`, "Discoverability"; the first budget is already
/// auto-featured by `CreateBudget`, so no ambiguity exists before this
/// point).
@injectable
class CountActiveBudgets {
  const CountActiveBudgets(this._repository);

  final BudgetRepository _repository;

  FutureResult<int> call() => _repository.countActiveBudgets();
}
