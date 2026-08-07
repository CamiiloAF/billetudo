import 'package:injectable/injectable.dart';

import '../../../../core/error/result.dart';
import '../../../transactions/domain/entities/date_period_filter.dart';
import '../../../transactions/domain/entities/transaction_filter.dart';
import '../../../transactions/domain/entities/transaction_with_details.dart';
import '../../../transactions/domain/repositories/transaction_repository.dart';

/// HU-03/HU-04: the transactions of one calendar `month`. Since the Home
/// hero/period-navigation redesign, this is used **only** as the fallback
/// total when no budget is featured (criterion 5): `HomeCubit` calls it with
/// `DateTime.now()`'s month at `start()`, then re-subscribes it to whatever
/// month the user picks from `MonthPickerSheet` via `HomeCubit.selectMonth`
/// (HU-04's calendar picker). It no longer feeds "Movimientos recientes"
/// (`WatchRecentTransactions` does, unbound). Reuses the Transactions
/// repository (excludes trashed rows on its own) so the Home never
/// re-implements the query.
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
