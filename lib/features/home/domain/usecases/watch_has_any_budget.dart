import 'package:injectable/injectable.dart';

import '../../../../core/error/result.dart';
import '../../../budgets/domain/repositories/budget_repository.dart';

/// Whether the user has ever created a budget that is still active (not
/// archived, not trashed) — the piece `HomeHeroStateResolver` needs to tell
/// `HomeHeroState.noBudgetEverCreated` apart from
/// `HomeHeroState.noBudgetFeatured` when no budget is currently featured.
///
/// Deliberately not a one-shot count: a user creating their first budget
/// while Home is open must flip the hero out of "nunca creó uno" without a
/// manual refresh, same reactive convention as every other Home input.
@injectable
class WatchHasAnyBudget {
  const WatchHasAnyBudget(this._repository);

  final BudgetRepository _repository;

  Stream<Result<bool>> call() => _repository
      .watchActiveBudgets()
      .map((result) => result.map((budgets) => budgets.isNotEmpty));
}
