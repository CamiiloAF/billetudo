import 'package:injectable/injectable.dart';

import '../../../error/result.dart';
import '../repositories/sync_quarantine_repository.dart';

/// Replays a single quarantined write against the cloud.
@injectable
class RetryQuarantinedOperation {
  const RetryQuarantinedOperation(this._repository);

  final SyncQuarantineRepository _repository;

  FutureResult<Unit> call(String id) => _repository.retry(id);
}
