import 'package:injectable/injectable.dart';

import '../../../../core/error/result.dart';
import '../entities/zero_based_summary.dart';
import '../repositories/budget_repository.dart';

/// HU-06: the "Modo sobres" hero — income of the current calendar month minus
/// what is assigned to active budgets. `null` payload means nothing to show.
@injectable
class GetZeroBasedSummary {
  const GetZeroBasedSummary(this._repository);

  final BudgetRepository _repository;

  Stream<Result<ZeroBasedSummary?>> call() =>
      _repository.watchZeroBasedSummary();
}
