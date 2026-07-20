import 'package:injectable/injectable.dart';
import 'package:powersync/powersync.dart' as ps;

import 'sync_status_source.dart';

/// The real [SyncStatusSource]: a thin adapter over [ps.PowerSyncDatabase].
///
/// Deliberately logic-free — it only copies flags — so that everything worth
/// testing lives in the repository, which no longer sees the package type.
@LazySingleton(as: SyncStatusSource)
class PowerSyncStatusSource implements SyncStatusSource {
  const PowerSyncStatusSource(this._powerSync);

  final ps.PowerSyncDatabase _powerSync;

  @override
  SyncSourceStatus get currentStatus => _snapshot(_powerSync.currentStatus);

  @override
  Stream<SyncSourceStatus> get statusStream =>
      _powerSync.statusStream.map(_snapshot);

  SyncSourceStatus _snapshot(ps.SyncStatus status) => SyncSourceStatus(
        connected: status.connected,
        uploading: status.uploading,
        downloading: status.downloading,
      );
}
