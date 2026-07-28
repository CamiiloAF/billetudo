import 'package:injectable/injectable.dart';

import '../../../error/result.dart';
import '../repositories/sync_quarantine_repository.dart';

/// Empties the quarantine without replaying anything.
@injectable
class DiscardAllQuarantinedOperations {
  const DiscardAllQuarantinedOperations(this._repository);

  final SyncQuarantineRepository _repository;

  FutureResult<Unit> call() => _repository.clearAll();
}
