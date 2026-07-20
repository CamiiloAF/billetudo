import '../entities/sync_state.dart';

/// Reads the live state of the backup/sync engine (HU-10).
abstract class SyncStatusRepository {
  /// Emits the current [SyncState] right away, then on every change.
  /// Never fails: sync problems are surfaced as [SyncState.offline], not as
  /// errors — the app works without the cloud.
  Stream<SyncState> watchSyncState();
}
