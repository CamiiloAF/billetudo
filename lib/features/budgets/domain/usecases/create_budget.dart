import 'package:injectable/injectable.dart';

import '../../../../core/error/result.dart';
import '../../../settings/domain/usecases/set_featured_budget.dart';
import '../entities/budget.dart';
import '../entities/budget_draft.dart';
import '../repositories/budget_repository.dart';

/// HU-01/HU-02/HU-03: creates a budget. Validation lives in
/// [BudgetDraft.validated]; the repository only persists what passed it.
///
/// Discoverability fix (`design-system/billetudo/pages/presupuestos.md`,
/// "Destacar presupuesto en Inicio" → "Discoverability"): the very first
/// active budget a user creates is auto-featured on Home
/// (`AppSettings.featuredBudgetId`), so the hero has something meaningful to
/// show without the user ever needing to find the `⋮` sheet's "Usar como
/// destacado" action. Reversible with the exact same ease as any manual pick
/// — nothing here prevents the user from unfeaturing or re-featuring later.
/// Only the *first* one gets this: from the second budget onward, the pick
/// stays exactly as it was (no re-featuring, no silent override of a choice
/// the user already made).
@injectable
class CreateBudget {
  const CreateBudget(this._repository, this._setFeaturedBudget);

  final BudgetRepository _repository;
  final SetFeaturedBudget _setFeaturedBudget;

  FutureResult<Budget> call(BudgetDraft draft) async {
    // Counted before the insert: this budget is not in the store yet, so
    // "0 active budgets right now" means "the one I'm about to create is the
    // first". A failed count is treated as "not the first" (no auto-feature)
    // rather than failing the whole creation over a non-critical read.
    final countResult = await _repository.countActiveBudgets();
    final isFirstBudget = countResult.fold(
      (failure) => false,
      (count) => count == 0,
    );

    final createResult = await draft.validated().fold<FutureResult<Budget>>(
          (failure) async => Left(failure),
          _repository.createBudget,
        );
    if (isFirstBudget) {
      await createResult.fold(
        (failure) async {},
        (budget) async {
          await _setFeaturedBudget(budgetId: budget.id);
        },
      );
    }
    return createResult;
  }
}
