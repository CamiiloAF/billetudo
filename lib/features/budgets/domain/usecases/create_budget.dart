import 'package:injectable/injectable.dart';

import '../../../../core/error/result.dart';
import '../entities/budget.dart';
import '../entities/budget_draft.dart';
import '../repositories/budget_repository.dart';

/// HU-01/HU-02/HU-03: creates a budget. Validation lives in
/// [BudgetDraft.validated]; the repository only persists what passed it.
@injectable
class CreateBudget {
  const CreateBudget(this._repository);

  final BudgetRepository _repository;

  FutureResult<Budget> call(BudgetDraft draft) =>
      draft.validated().fold<FutureResult<Budget>>(
            (failure) async => Left(failure),
            _repository.createBudget,
          );
}
