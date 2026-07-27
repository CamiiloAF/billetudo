import 'package:injectable/injectable.dart';

import '../../../../core/error/result.dart';
import '../entities/debt_detail.dart';
import '../repositories/debt_repository.dart';

/// HU-04: reactive detail of one debt — the debt, its derived balance/progress
/// and its unified newest-first history.
@injectable
class WatchDebtDetail {
  const WatchDebtDetail(this._repository);

  final DebtRepository _repository;

  Stream<Result<DebtDetail>> call(String debtId) =>
      _repository.watchDebtDetail(debtId);
}
