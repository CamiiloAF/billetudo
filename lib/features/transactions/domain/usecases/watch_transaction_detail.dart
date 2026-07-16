import 'package:injectable/injectable.dart';

import '../../../../core/error/result.dart';
import '../entities/transaction_with_details.dart';
import '../repositories/transaction_repository.dart';

/// HU-08: reactive, enriched detail of a single transaction.
@injectable
class WatchTransactionDetail {
  const WatchTransactionDetail(this._repository);

  final TransactionRepository _repository;

  Stream<Result<TransactionWithDetails>> call(String id) =>
      _repository.watchTransactionDetail(id);
}
