import 'package:injectable/injectable.dart';
import 'package:powersync/powersync.dart' show PowerSyncDatabase;

/// Erases every row on this device, across every table, **without touching the
/// cloud copy**. Used by two different flows, and the difference matters:
///
///  - HU-06 ("Cerrar sesión" → "Borrar los datos de este teléfono"): the cloud
///    account stays alive and must come back untouched on the next sign-in.
///  - HU-07 paso 2 ("Borrar también los datos de este dispositivo"): the cloud
///    copy is already gone (`AuthRepository.deleteAccount` ran the
///    `delete-account` Edge Function first).
///
/// Never deletes row by row through Drift. Drift writes through PowerSync's
/// *views* (decision #6, docs/requirements/05-auth-sync.md), whose `INSTEAD OF`
/// triggers record every write in the upload queue (`ps_crud`) — so a local
/// `DELETE` is queued as a `DELETE` for Postgres and gets uploaded on the next
/// sign-in, wiping the cloud too. That is exactly the data-loss bug this
/// datasource caused for HU-06.
///
/// `disconnectAndClear` is PowerSync's own log-out primitive: it disconnects,
/// then `powersync_clear` empties the data tables **and** the sync bookkeeping
/// (`ps_crud`, `ps_oplog`, `ps_buckets`, `ps_untyped`, `ps_updated_rows`,
/// `ps_sync_state`, `ps_stream_subscriptions`), so nothing is left to upload.
/// The database stays open and queryable, just empty.
///
/// `clearLocal` keeps its default `true`: this project declares no
/// `Table.localOnly` in `core/database/powersync_schema.dart`, so the flag has
/// nothing to spare today — and the user explicitly asked for *everything* on
/// this device to go. If a local-only table is ever added, revisit this
/// deliberately instead of inheriting the default.
///
/// Only ever runs on the user's explicit, unpreselected choice — never
/// silently.
@lazySingleton
class LocalDataWipeDatasource {
  const LocalDataWipeDatasource(this._powerSync);

  final PowerSyncDatabase _powerSync;

  /// Also disconnects sync on its own, so callers don't need to sequence a
  /// `disconnect()` before this (`SignOutWithLocalDataChoice` still signs out
  /// first for its own reason: a failed sign-out after a wipe would leave a
  /// live session over an empty database).
  Future<void> wipeAll() => _powerSync.disconnectAndClear();
}
