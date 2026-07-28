import 'package:injectable/injectable.dart';

import '../../../error/result.dart';
import '../repositories/sync_quarantine_repository.dart';

/// Replays every quarantined write. Returns how many of them succeeded, so
/// the caller can tell "all recovered" from "some still failing".
@injectable
class RetryAllQuarantinedOperations {
  const RetryAllQuarantinedOperations(this._repository);

  final SyncQuarantineRepository _repository;

  FutureResult<int> call() => _repository.retryAll();
}
