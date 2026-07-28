import 'package:injectable/injectable.dart';

import '../entities/sync_log_entry.dart';
import '../repositories/sync_log_repository.dart';

/// Watches the on-device sync log, newest entry first.
@injectable
class WatchSyncLog {
  const WatchSyncLog(this._repository);

  final SyncLogRepository _repository;

  Stream<List<SyncLogEntry>> call() => _repository.watchEntries();
}
