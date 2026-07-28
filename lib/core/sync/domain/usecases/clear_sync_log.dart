import 'package:injectable/injectable.dart';

import '../../../error/result.dart';
import '../repositories/sync_log_repository.dart';

/// Empties the on-device sync log.
@injectable
class ClearSyncLog {
  const ClearSyncLog(this._repository);

  final SyncLogRepository _repository;

  FutureResult<Unit> call() => _repository.clear();
}
