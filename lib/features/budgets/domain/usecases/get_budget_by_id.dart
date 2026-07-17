import 'package:injectable/injectable.dart';

import '../../../../core/error/result.dart';
import '../entities/budget_detail_data.dart';
import '../repositories/budget_repository.dart';

/// HU-04/HU-05: the reactive detail bundle for one budget.
@injectable
class GetBudgetById {
  const GetBudgetById(this._repository);

  final BudgetRepository _repository;

  Stream<Result<BudgetDetailData>> call(String id) =>
      _repository.watchBudgetDetail(id);
}
