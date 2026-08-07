import 'package:injectable/injectable.dart';

import '../../../../core/error/result.dart';
import '../repositories/app_settings_repository.dart';

/// Clears the budget featured on the Home hero card
/// (`design-system/billetudo/pages/ajustes.md`, "Presupuesto destacado"):
/// sets `AppSettings.featuredBudgetMode` to `none` — the user explicitly
/// wants no featured budget, with no automatic global+monthly fallback
/// either (`BudgetHeroSelector`) — and resets `featuredBudgetId` to `null`
/// since it stops being relevant. Distinct from `SetFeaturedBudget(null)`,
/// which no longer exists: a bare null id used to be indistinguishable from
/// "never picked one", silently re-enabling the automatic fallback.
@injectable
class ClearFeaturedBudget {
  const ClearFeaturedBudget(this._repository);

  final AppSettingsRepository _repository;

  FutureResult<Unit> call() => _repository.clearFeaturedBudget();
}
