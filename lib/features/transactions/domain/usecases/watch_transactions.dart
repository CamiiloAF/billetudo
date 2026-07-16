import 'package:injectable/injectable.dart';

import '../../../../core/error/result.dart';
import '../entities/transaction_filter.dart';
import '../entities/transaction_with_details.dart';
import '../repositories/transaction_repository.dart';

/// HU-06: reactive, filtered, searched and ordered transaction list. Excludes
/// trashed rows (`deletedAt != null`).
@injectable
class WatchTransactions {
  const WatchTransactions(this._repository);

  final TransactionRepository _repository;

  Stream<Result<List<TransactionWithDetails>>> call(TransactionFilter filter) =>
      _repository.watchTransactions(filter);
}
