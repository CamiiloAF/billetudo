import 'package:injectable/injectable.dart';

import '../entities/sync_state.dart';
import '../repositories/sync_status_repository.dart';

/// Watches the backup/sync state for the passive indicator on the Home
/// header (HU-10). Transversal on purpose: Ajustes will want the same stream.
@injectable
class WatchSyncStatus {
  const WatchSyncStatus(this._repository);

  final SyncStatusRepository _repository;

  Stream<SyncState> call() => _repository.watchSyncState();
}
