import 'package:injectable/injectable.dart';

import '../../../../core/error/result.dart';
import '../entities/budget_with_progress.dart';
import '../repositories/budget_repository.dart';

/// HU-11: closed budgets (history), with the result of the period they closed
/// in.
@injectable
class GetArchivedBudgets {
  const GetArchivedBudgets(this._repository);

  final BudgetRepository _repository;

  Stream<Result<List<BudgetWithProgress>>> call() =>
      _repository.watchArchivedBudgets();
}
