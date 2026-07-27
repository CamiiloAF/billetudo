import 'package:injectable/injectable.dart';

import '../../../../core/error/result.dart';
import '../entities/debts_summary.dart';
import '../repositories/debt_repository.dart';

/// HU-04: reactive list of active debts with their derived balances and
/// per-currency totals.
@injectable
class WatchDebts {
  const WatchDebts(this._repository);

  final DebtRepository _repository;

  Stream<Result<DebtsSummary>> call() => _repository.watchDebts();
}
