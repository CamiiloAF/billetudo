import 'package:injectable/injectable.dart';

import '../../../../core/error/result.dart';
import '../repositories/app_settings_repository.dart';

/// Manually picks the budget featured on the Home hero card
/// (`design-system/billetudo/pages/ajustes.md`, "Presupuesto destacado"),
/// setting `AppSettings.featuredBudgetMode` to `manual` alongside the id. To
/// clear the featured budget instead (mode `none`, no automatic fallback),
/// use `ClearFeaturedBudget`.
@injectable
class SetFeaturedBudget {
  const SetFeaturedBudget(this._repository);

  final AppSettingsRepository _repository;

  FutureResult<Unit> call({required String budgetId}) =>
      _repository.setFeaturedBudget(budgetId: budgetId);
}
