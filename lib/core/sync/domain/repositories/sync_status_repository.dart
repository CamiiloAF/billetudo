import '../../../error/result.dart';
import '../entities/sync_state.dart';

/// Reads the live state of the backup/sync engine (HU-10).
abstract class SyncStatusRepository {
  /// Emits the current [SyncState] right away, then on every change.
  /// Never fails: sync problems are surfaced as [SyncState.offline], not as
  /// errors — the app works without the cloud.
  Stream<SyncState> watchSyncState();

  /// How many local changes have not reached the cloud yet, read once.
  ///
  /// Unlike [watchSyncState] this one *can* fail: the caller (HU-06) warns
  /// about data loss with it, so "we could not count" must not be silently
  /// flattened into "there is nothing pending".
  FutureResult<int> pendingUploadCount();
}
