import 'package:injectable/injectable.dart';
import 'package:powersync/powersync.dart' show PowerSyncDatabase;

import '../../../../core/crash/crash_reporter.dart';
import '../../../../core/error/result.dart';
import '../../../../core/sync/data/datasources/sync_retry_ledger_store.dart';
import '../../../../core/sync/domain/repositories/sync_log_repository.dart';
import '../../../../core/sync/domain/repositories/sync_quarantine_repository.dart';

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
/// *views* (decision #6, docs/requirements/fase-1/05-auth-sync.md), whose `INSTEAD OF`
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
/// `clearLocal` keeps its default `true`, and since schemaVersion 30 that is a
/// deliberate decision rather than an empty one. The project now declares one
/// local-only table in `core/database/powersync_schema.dart` — `ai_messages`,
/// the AI assistant's chat history, which never reaches Postgres — and
/// `clearLocal` is precisely the flag that decides its fate:
/// `disconnectAndClear({bool clearLocal = true})` runs
/// `select powersync_clear(?)` with `clearLocal ? 1 : 0`, and its own doc says
/// "To preserve data in local-only tables, set `clearLocal` to false". Left at
/// `true`, the chat history is wiped along with everything else — which is
/// what both callers must do: HU-06 asks for *everything* on this device to
/// go, and after HU-07 the conversation would be the last surviving trace of
/// an account whose cloud copy is already gone (and the only copy that ever
/// existed of it, since it was never synced). Do not flip this to `false`
/// without re-reading both flows.
///
/// `disconnectAndClear` only reaches the PowerSync-managed SQLite file. Three
/// sync diagnostics stores live deliberately outside of it, as plain JSON
/// under `<app documents>/sync/` (see `SyncStorageDirectory`'s doc comment for
/// why): the quarantine, the retry ledger and the local sync log. Left alone,
/// a wiped device kept showing stale quarantine entries ("N cambios están
/// solo en este teléfono") for data that no longer existed anywhere. They are
/// cleared here too, alongside the PowerSync database, so a wipe is really a
/// wipe.
///
/// Only ever runs on the user's explicit, unpreselected choice — never
/// silently.
@lazySingleton
class LocalDataWipeDatasource {
  const LocalDataWipeDatasource(
    this._powerSync,
    this._quarantine,
    this._retryLedger,
    this._log,
    this._crashReporter,
  );

  final PowerSyncDatabase _powerSync;
  final SyncQuarantineRepository _quarantine;
  final SyncRetryLedgerStore _retryLedger;
  final SyncLogRepository _log;
  final CrashReporter _crashReporter;

  /// Also disconnects sync on its own, so callers don't need to sequence a
  /// `disconnect()` before this (`SignOutWithLocalDataChoice` still signs out
  /// first for its own reason: a failed sign-out after a wipe would leave a
  /// live session over an empty database).
  Future<void> wipeAll() async {
    await _powerSync.disconnectAndClear();
    // Quarantine first: `SyncQuarantineRepository.clearAll` appends its own
    // "quarantine cleared" entry to the sync log, and the log wipe right
    // after removes that entry too — a wiped device should show no trace of
    // its own wipe.
    await _clearQuietly(_quarantine.clearAll,
        'could not clear the sync quarantine during a local wipe');
    await _clearRetryLedgerQuietly();
    await _clearQuietly(
        _log.clear, 'could not clear the sync log during a local wipe');
  }

  Future<void> _clearQuietly(
    FutureResult<Unit> Function() clear,
    String context,
  ) async {
    final result = await clear();
    await result.fold(
      (failure) => _crashReporter.recordFailure(failure, context: context),
      (_) async {},
    );
  }

  Future<void> _clearRetryLedgerQuietly() async {
    try {
      await _retryLedger.removeAll();
    } on Object catch (e, stackTrace) {
      await _crashReporter.recordError(
        e,
        stackTrace,
        context: 'could not clear the sync retry ledger during a local wipe',
      );
    }
  }
}
