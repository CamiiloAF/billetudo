import 'package:injectable/injectable.dart';

import '../../../../core/error/result.dart';
import '../../../transactions/domain/entities/transaction_with_details.dart';
import '../../../transactions/domain/repositories/transaction_repository.dart';

/// HU-05: "Movimientos recientes" — a literal activity feed of every active
/// account's most recent movements, with **no** month/period filter. Unlike
/// the hero's spending total (which stays scoped to a period), this list is
/// deliberately decoupled from whatever period is being navigated elsewhere
/// on Home, so it always shows the latest activity regardless of the hero's
/// selected budget period.
///
/// Reuses the Transactions repository (excludes trashed rows on its own) so
/// Home never re-implements the query. Ordered newest first; the display cap
/// (`HomeSnapshot.recentActivityLimit`) is applied by `HomeSnapshot.from`, not
/// here.
@injectable
class WatchRecentTransactions {
  const WatchRecentTransactions(this._repository);

  final TransactionRepository _repository;

  Stream<Result<List<TransactionWithDetails>>> call() =>
      _repository.watchRecentTransactions();
}
