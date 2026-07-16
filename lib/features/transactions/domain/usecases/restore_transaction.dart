import 'package:injectable/injectable.dart';

import '../../../../core/error/result.dart';
import '../repositories/transaction_repository.dart';

/// HU-05: undo a delete from the "Deshacer" snackbar, clearing `deletedAt`.
@injectable
class RestoreTransaction {
  const RestoreTransaction(this._repository);

  final TransactionRepository _repository;

  FutureResult<Unit> call(String id) => _repository.restoreTransaction(id);
}
