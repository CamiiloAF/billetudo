import 'package:injectable/injectable.dart';

import '../../domain/entities/sync_state.dart';
import '../../domain/repositories/sync_status_repository.dart';
import '../datasources/sync_status_source.dart';

/// Translates the sync engine's status into the domain's [SyncState].
///
/// It reads the engine through [SyncStatusSource], never through PowerSync
/// directly: the package type stops at that adapter and never reaches
/// `domain` or `presentation`.
@LazySingleton(as: SyncStatusRepository)
class SyncStatusRepositoryImpl implements SyncStatusRepository {
  const SyncStatusRepositoryImpl(this._source);

  final SyncStatusSource _source;

  @override
  Stream<SyncState> watchSyncState() async* {
    // `statusStream` only emits on change, so seed with the current value —
    // otherwise the indicator would sit on its default until sync moved.
    yield _map(_source.currentStatus);
    yield* _source.statusStream.map(_map).distinct();
  }

  /// Signed out, the repository never calls `connect()` (and sign-out calls
  /// `disconnect()`), so `connected` is false and this reports `offline` —
  /// the product decision for "no session" without dragging auth into core.
  ///
  /// `connecting` counts as offline: there is no link yet, and a spinner that
  /// starts before anything is actually moving reads as noise.
  SyncState _map(SyncSourceStatus status) {
    if (status.uploading || status.downloading) {
      return SyncState.syncing;
    }
    if (status.connected) {
      return SyncState.synced;
    }
    return SyncState.offline;
  }
}
