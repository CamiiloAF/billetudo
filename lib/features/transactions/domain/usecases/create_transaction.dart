import 'package:injectable/injectable.dart';

import '../../../../core/error/result.dart';
import '../entities/transaction.dart';
import '../entities/transaction_draft.dart';
import '../repositories/transaction_repository.dart';

/// HU-01/HU-02/HU-03: creates a transaction (expense, income or transfer).
///
/// Validation (accountId required, positive `amountMinor`, category kind
/// restricted to the transaction's money direction, distinct transfer
/// accounts) lives in [TransactionDraft.validated]; the repository only
/// persists what already passed it.
@injectable
class CreateTransaction {
  const CreateTransaction(this._repository);

  final TransactionRepository _repository;

  FutureResult<Transaction> call(TransactionDraft draft) =>
      draft.validated().fold<FutureResult<Transaction>>(
            (failure) async => Left(failure),
            _repository.createTransaction,
          );
}
