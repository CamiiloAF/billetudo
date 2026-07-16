import 'package:injectable/injectable.dart';

import '../../../../core/error/result.dart';
import '../entities/transaction.dart';
import '../entities/transaction_draft.dart';
import '../repositories/transaction_repository.dart';

/// HU-04: edits a transaction. Every field is editable except `source`,
/// which the repository leaves untouched regardless of what `draft.source`
/// carries.
///
/// Same validation as `CreateTransaction` via [TransactionDraft.validated].
/// The edit-impact warning on a linked recurring/goal/debt (see the HU) is
/// computed separately by `GetTransactionEditImpact`, so the caller can show
/// it *before* confirming this write.
@injectable
class UpdateTransaction {
  const UpdateTransaction(this._repository);

  final TransactionRepository _repository;

  FutureResult<Transaction> call(TransactionDraft draft) =>
      draft.validated().fold<FutureResult<Transaction>>(
            (failure) async => Left(failure),
            _repository.updateTransaction,
          );
}
