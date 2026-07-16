import 'package:injectable/injectable.dart';

import '../../../../core/error/result.dart';
import '../repositories/transaction_repository.dart';

/// HU-05: soft-deletes a transaction into the trash (`deletedAt`), recoverable
/// via `RestoreTransaction` from the "Deshacer" snackbar. Never stamps
/// `tombstonedAt` — there is no referential-integrity concern here.
@injectable
class DeleteTransaction {
  const DeleteTransaction(this._repository);

  final TransactionRepository _repository;

  FutureResult<Unit> call(String id) => _repository.deleteTransaction(id);
}
