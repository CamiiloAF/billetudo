import 'package:injectable/injectable.dart';

import '../entities/sync_status_snapshot.dart';
import '../repositories/sync_status_repository.dart';

/// Watches the backup state with its detail: last successful sync and how many
/// writes are held in quarantine.
///
/// Separate from `WatchSyncStatus` on purpose — the Home's passive icon only
/// needs the coarse state, and a status/diagnostics screen needs all of it.
@injectable
class WatchSyncStatusDetails {
  const WatchSyncStatusDetails(this._repository);

  final SyncStatusRepository _repository;

  Stream<SyncStatusSnapshot> call() => _repository.watchStatus();
}
