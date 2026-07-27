import 'package:injectable/injectable.dart';

import '../../../../core/error/result.dart';
import '../repositories/debt_repository.dart';

/// HU-05: logical delete via `deletedAt` (papelera/undo). The debt's cash
/// `Transaction`s are NOT touched (they were real account movements); they keep
/// pointing at the trashed debt and start counting again on `RestoreDebt`.
@injectable
class DeleteDebt {
  const DeleteDebt(this._repository);

  final DebtRepository _repository;

  FutureResult<Unit> call(String id) => _repository.deleteDebt(id);
}
