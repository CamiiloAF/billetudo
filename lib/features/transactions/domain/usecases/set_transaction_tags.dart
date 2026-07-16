import 'package:injectable/injectable.dart';

import '../../../../core/error/result.dart';
import '../repositories/transaction_repository.dart';

/// HU-07: replaces the full set of tags assigned to a transaction.
@injectable
class SetTransactionTags {
  const SetTransactionTags(this._repository);

  final TransactionRepository _repository;

  FutureResult<Unit> call(String transactionId, List<String> tagIds) =>
      _repository.setTransactionTags(transactionId, tagIds);
}
