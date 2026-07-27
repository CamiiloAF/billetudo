import 'package:injectable/injectable.dart';

import '../../../../core/error/result.dart';
import '../repositories/debt_repository.dart';

/// HU-05: undo from the trash. Clears `deletedAt`; the debt and all its ledger
/// events count again.
@injectable
class RestoreDebt {
  const RestoreDebt(this._repository);

  final DebtRepository _repository;

  FutureResult<Unit> call(String id) => _repository.restoreDebt(id);
}
