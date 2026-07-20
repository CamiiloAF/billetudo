import 'package:injectable/injectable.dart';
import 'package:powersync/powersync.dart' as ps;

import '../../domain/entities/sync_state.dart';
import '../../domain/repositories/sync_status_repository.dart';

/// Translates PowerSync's `SyncStatus` into the domain's [SyncState].
///
/// This is the only place in the app that knows the sync engine exists: the
/// package type stops here and never reaches `domain` or `presentation`.
@LazySingleton(as: SyncStatusRepository)
class SyncStatusRepositoryImpl implements SyncStatusRepository {
  const SyncStatusRepositoryImpl(this._powerSync);

  final ps.PowerSyncDatabase _powerSync;

  @override
  Stream<SyncState> watchSyncState() async* {
    // `statusStream` only emits on change, so seed with the current value —
    // otherwise the indicator would sit on its default until sync moved.
    yield _map(_powerSync.currentStatus);
    yield* _powerSync.statusStream.map(_map).distinct();
  }

  /// Signed out, the repository never calls `connect()` (and sign-out calls
  /// `disconnect()`), so `connected` is false and this reports `offline` —
  /// the product decision for "no session" without dragging auth into core.
  ///
  /// `connecting` counts as offline: there is no link yet, and a spinner that
  /// starts before anything is actually moving reads as noise.
  SyncState _map(ps.SyncStatus status) {
    if (status.uploading || status.downloading) {
      return SyncState.syncing;
    }
    if (status.connected) {
      return SyncState.synced;
    }
    return SyncState.offline;
  }
}
