import 'package:injectable/injectable.dart';

import '../../../../core/error/result.dart';
import '../entities/budget.dart';
import '../entities/budget_draft.dart';
import '../repositories/budget_repository.dart';

/// HU-09: edits a budget (amount, cadence, dates, scope, threshold). Validation
/// lives in [BudgetDraft.validated]; editing never recomputes past periods.
@injectable
class UpdateBudget {
  const UpdateBudget(this._repository);

  final BudgetRepository _repository;

  FutureResult<Budget> call(BudgetDraft draft) =>
      draft.validated().fold<FutureResult<Budget>>(
            (failure) async => Left(failure),
            _repository.updateBudget,
          );
}
