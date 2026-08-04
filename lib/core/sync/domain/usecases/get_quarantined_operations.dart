import 'package:injectable/injectable.dart';

import '../../../error/result.dart';
import '../entities/quarantined_operation.dart';
import '../repositories/sync_quarantine_repository.dart';

/// Reads the quarantine once — used where a snapshot is enough (a warning
/// before wiping local data, for instance).
@injectable
class GetQuarantinedOperations {
  const GetQuarantinedOperations(this._repository);

  final SyncQuarantineRepository _repository;

  FutureResult<List<QuarantinedOperation>> call() => _repository.getFailures();
}
