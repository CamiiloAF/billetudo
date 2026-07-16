import 'package:injectable/injectable.dart';

import '../../../../core/error/result.dart';
import '../../../transactions/domain/entities/date_period_filter.dart';
import '../../../transactions/domain/entities/transaction_filter.dart';
import '../../../transactions/domain/entities/transaction_with_details.dart';
import '../../../transactions/domain/repositories/transaction_repository.dart';

/// HU-03/HU-04/HU-05: the transactions of one calendar `month`, the Home's unit
/// of navigation. Reuses the Transactions repository (excludes trashed rows on
/// its own) so the Home never re-implements the query.
@injectable
class WatchMonthTransactions {
  const WatchMonthTransactions(this._repository);

  final TransactionRepository _repository;

  Stream<Result<List<TransactionWithDetails>>> call(DateTime month) =>
      _repository.watchTransactions(
        TransactionFilter(
          datePeriod: DatePeriodFilter.granular(DateGranularity.month, month),
        ),
      );
}
