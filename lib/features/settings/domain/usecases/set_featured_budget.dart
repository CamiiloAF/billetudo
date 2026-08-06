import 'package:injectable/injectable.dart';

import '../../../../core/error/result.dart';
import '../repositories/app_settings_repository.dart';

/// Picks (or clears, with `null`) the budget manually featured on the Home
/// hero card (`design-system/billetudo/pages/ajustes.md`, "Presupuesto
/// destacado"). `null` restores the automatic global+monthly selection
/// (`BudgetHeroSelector`).
@injectable
class SetFeaturedBudget {
  const SetFeaturedBudget(this._repository);

  final AppSettingsRepository _repository;

  FutureResult<Unit> call({required String? budgetId}) =>
      _repository.setFeaturedBudgetId(budgetId: budgetId);
}
