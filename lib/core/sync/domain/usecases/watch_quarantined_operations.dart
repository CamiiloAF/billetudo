import 'package:injectable/injectable.dart';

import '../entities/quarantined_operation.dart';
import '../repositories/sync_quarantine_repository.dart';

/// Watches the writes the cloud rejected permanently (sync diagnostics).
@injectable
class WatchQuarantinedOperations {
  const WatchQuarantinedOperations(this._repository);

  final SyncQuarantineRepository _repository;

  Stream<List<QuarantinedOperation>> call() => _repository.watchFailures();
}
