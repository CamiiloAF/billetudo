import 'package:injectable/injectable.dart';

import '../../../../core/error/result.dart';
import '../entities/budget_with_progress.dart';
import '../repositories/budget_repository.dart';

/// HU-04: active budgets with their current-period progress.
@injectable
class GetActiveBudgets {
  const GetActiveBudgets(this._repository);

  final BudgetRepository _repository;

  Stream<Result<List<BudgetWithProgress>>> call() =>
      _repository.watchActiveBudgets();
}
