import 'package:injectable/injectable.dart';

import '../../../../core/error/result.dart';
import '../../../settings/domain/entities/app_settings.dart'
    show FeaturedBudgetMode;
import '../entities/budget_with_progress.dart';
import '../repositories/budget_repository.dart';
import '../services/budget_hero_selector.dart';

/// Home's automatic hero pick (`docs/requirements/fase-1/04-inicio.md`): the single
/// active budget, if any, that is both global (no account/category scope,
/// `BudgetScope.isGlobal`) and on the `BudgetPeriod.monthly` cadence. Home
/// only ever represents *this* exact profile — a global budget on another
/// period, or one scoped to accounts/categories, falls back to the "sin
/// presupuesto" hero state instead of being force-fit into it.
///
/// The selection rule itself lives in [BudgetHeroSelector] (shared with
/// `WatchFeaturedBudgetProgress`, which layers a manual override on top of
/// this same automatic fallback) — this use case only wires it to the
/// repository stream.
@injectable
class WatchGlobalMonthlyBudgetProgress {
  const WatchGlobalMonthlyBudgetProgress(this._repository);

  final BudgetRepository _repository;

  Stream<Result<BudgetWithProgress?>> call() =>
      _repository.watchActiveBudgets().map(
            (result) => result.map(
              // Always `automatic`: this use case deliberately ignores
              // `AppSettings.featuredBudgetMode`/`featuredBudgetId` — it only
              // ever answers the automatic global+monthly pick, never a
              // manual override or `none`.
              (budgets) => BudgetHeroSelector.pick(
                budgets,
                mode: FeaturedBudgetMode.automatic,
              ),
            ),
          );
}
