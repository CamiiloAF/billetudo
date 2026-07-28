import 'package:injectable/injectable.dart';

import '../../../error/result.dart';
import '../repositories/sync_quarantine_repository.dart';

/// Drops a quarantined write without replaying it. Explicit user decision:
/// the data in that write is not going to reach the cloud.
@injectable
class DiscardQuarantinedOperation {
  const DiscardQuarantinedOperation(this._repository);

  final SyncQuarantineRepository _repository;

  FutureResult<Unit> call(String id) => _repository.clear(id);
}
