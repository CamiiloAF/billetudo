import 'package:injectable/injectable.dart';
import 'package:powersync/powersync.dart' as ps;
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/config/env.dart';
import '../../../../core/crash/crash_reporter.dart';
import '../../../../core/sync/data/datasources/sync_error_classifier.dart';
import '../../../../core/sync/data/datasources/sync_operation_uploader.dart';
import '../../../../core/sync/data/datasources/sync_retry_watchdog.dart';
import '../../../../core/sync/domain/entities/sync_failure_kind.dart';
import '../../../../core/sync/domain/entities/sync_log_entry.dart';
import '../../../../core/sync/domain/entities/sync_operation.dart';
import '../../../../core/sync/domain/repositories/sync_log_repository.dart';
import '../../../../core/sync/domain/repositories/sync_quarantine_repository.dart';

/// Bridges PowerSync (HU-04/HU-05) to Supabase: supplies the JWT the sync
/// stream needs, and replicates PowerSync's local write queue against
/// Supabase's REST API so every Drift write that reached PowerSync (see
/// `core/database/database_connection.dart`, decision #6,
/// docs/requirements/fase-1/05-auth-sync.md) ends up in Postgres too.
///
/// Lives under `features/auth/data/` rather than `core/` because it is a
/// concrete Supabase-backed implementation the same way
/// `google_auth_datasource.dart` is — `core/` only holds the transport-agnostic
/// pieces (the schema, the Drift-over-PowerSync connection).
@lazySingleton
class PowerSyncConnector extends ps.PowerSyncBackendConnector {
  PowerSyncConnector(
    this._supabase,
    this._uploader,
    this._quarantine,
    this._log,
    this._crash,
    this._watchdog,
  );

  final SupabaseClient _supabase;
  final SyncOperationUploader _uploader;
  final SyncQuarantineRepository _quarantine;
  final SyncLogRepository _log;
  final CrashReporter _crash;
  final SyncRetryWatchdog _watchdog;

  /// Last session the log reported on, so credential refreshes (which happen
  /// on a timer) do not flood the ring buffer with identical lines.
  String? _loggedUserId;
  bool _loggedSignedOut = false;

  @override
  Future<ps.PowerSyncCredentials?> fetchCredentials() async {
    final session = _supabase.auth.currentSession;
    if (session == null) {
      // Not signed in: HU-01, local-first, no error — just nothing to sync.
      if (!_loggedSignedOut) {
        _loggedSignedOut = true;
        _loggedUserId = null;
        await _log.record(
          event: SyncLogEvent.connection,
          message: 'no session',
        );
      }
      return null;
    }
    if (_loggedUserId != session.user.id) {
      _loggedUserId = session.user.id;
      _loggedSignedOut = false;
      await _log.record(
        event: SyncLogEvent.connection,
        message: 'credentials issued',
      );
    }
    return ps.PowerSyncCredentials(
      endpoint: Env.powerSyncUrl,
      token: session.accessToken,
      userId: session.user.id,
    );
  }

  /// Uploads one PowerSync transaction, **operation by operation**.
  ///
  /// The failure handling used to wrap the whole `for`, so one rejected write
  /// aborted the other nine in its batch, and anything the old regex list did
  /// not recognise as fatal was rethrown and retried forever. Since the upload
  /// queue is FIFO, that single operation blocked every later write of every
  /// table — for three days, with no symptom in the app, until a reinstall
  /// wiped 89 unsynced changes along with the local database. The trigger was
  /// a `PGRST204`: Postgres was missing `debts.closed_at`.
  ///
  /// So now:
  ///  - a **transient** failure still aborts the whole transaction (atomicity
  ///    matters: the batch is retried as a unit),
  ///  - a **permanent** failure (broken schema, invalid data, RLS) takes only
  ///    its own operation out — quarantined locally, reported — and the rest
  ///    of the batch still goes up,
  ///  - a transient failure that keeps coming back is watched by
  ///    [SyncRetryWatchdog]: past its two gates it is quarantined too, so an
  ///    error code nobody classified cannot reproduce the incident,
  ///  - and the transaction is completed either way, so the queue always
  ///    advances instead of jamming behind a write that can never succeed.
  @override
  Future<void> uploadData(ps.PowerSyncDatabase database) async {
    final transaction = await database.getNextCrudTransaction();
    if (transaction == null) {
      return;
    }

    final operations = transaction.crud.map(_toSyncOperation).toList();
    await _log.record(
      event: SyncLogEvent.uploadStarted,
      message: 'push ${operations.length} ops',
    );

    var quarantined = 0;
    for (final operation in operations) {
      try {
        await _uploader.upload(operation);
        // It went through: whatever this operation had accumulated in the
        // watchdog's ledger is history, and must not count towards a future
        // failure of the same row.
        await _watchdog.forget(operation);
      } catch (error, stackTrace) {
        var kind = SyncErrorClassifier.classify(error);
        final code = SyncErrorClassifier.codeOf(error);
        if (kind.isTransient) {
          final verdict = await _watchdog.registerFailure(
            operation: operation,
            error: error,
          );
          if (!verdict.shouldQuarantine) {
            // Console-shaped and terse on purpose (`toLogLine()`): the table
            // and code are already prepended by the log line itself, and
            // `$error` is reserved for the Sentry `context` below — a raw
            // exception can be arbitrarily long and would blow the one-line
            // density the "Registro técnico" frame (`T7Iw0C`) is built for.
            await _log.record(
              event: SyncLogEvent.uploadRetry,
              level: SyncLogLevel.warning,
              message: 'retry #${verdict.attempts}',
              code: code,
              tableName: operation.tableName,
            );
            await _crash.recordError(
              error,
              stackTrace,
              context: 'PowerSync upload is retrying a transaction '
                  '(table ${operation.tableName}, code $code)',
            );
            // No `transaction.complete()`: PowerSync keeps the batch and tries
            // the whole thing again. Upserts are idempotent, so replaying the
            // operations that already succeeded is safe.
            rethrow;
          }

          // The watchdog tripped: this failure was never classified as
          // permanent, it simply kept being rejected long enough that letting
          // it hold the FIFO queue became the bigger risk. Quarantining it is
          // what keeps every other write moving; nothing is lost, the record
          // stays retryable by hand.
          kind = SyncFailureKind.stuck;
          quarantined++;
          await _quarantine.record(
            operation: operation,
            kind: kind,
            errorCode: code,
            errorMessage: 'retry watchdog: ${verdict.describe()} '
                'with no verdict — $error',
          );
          await _watchdog.forget(operation);
          await _log.record(
            event: SyncLogEvent.watchdogQuarantined,
            level: SyncLogLevel.error,
            message: 'stalled ${verdict.attempts}x/'
                '${verdict.stuckFor.inHours}h',
            code: code,
            tableName: operation.tableName,
          );
          // Highest severity, and worded so it cannot be confused with a
          // classified rejection: reaching this means a failure mode nobody
          // foresaw is in production. That signal is exactly what was missing
          // for three days in the 2026-07-25 incident.
          await _crash.recordError(
            error,
            stackTrace,
            context: 'UNCLASSIFIED SYNC FAILURE — the retry watchdog '
                'quarantined an operation after ${verdict.describe()} '
                '(table ${operation.tableName}, code $code). A failure mode '
                'the classifier does not know about is blocking uploads.',
            fatal: true,
          );
          continue;
        }

        quarantined++;
        await _quarantine.record(
          operation: operation,
          kind: kind,
          errorCode: code,
          errorMessage: error.toString(),
        );
        await _watchdog.forget(operation);
        await _log.record(
          event: SyncLogEvent.quarantined,
          level: SyncLogLevel.error,
          message: 'quarantined (${kind.name})',
          code: code,
          tableName: operation.tableName,
        );
        // `brokenSchema` is a deployment bug (the app shipped ahead of the
        // database migration) and affects every write to that table, so it is
        // reported as fatal to make it page-worthy. Invalid data / RLS is a
        // single-row problem: reported, not fatal.
        await _crash.recordError(
          error,
          stackTrace,
          context: 'PowerSync upload quarantined a ${kind.name} rejection '
              '(table ${operation.tableName}, code $code)',
          fatal: kind == SyncFailureKind.brokenSchema,
        );
      }
    }

    await _log.record(
      event: SyncLogEvent.uploadFinished,
      level: quarantined > 0 ? SyncLogLevel.warning : SyncLogLevel.info,
      message: '${operations.length - quarantined} uploaded, '
          '$quarantined quarantined',
    );
    // Reached only when no operation failed transiently: completing here is
    // what lets the queue move past the permanently-rejected writes, which are
    // now held in the quarantine instead of being lost.
    await transaction.complete();
  }

  /// Translates PowerSync's queue entry into the transport-agnostic entity the
  /// uploader and the quarantine share. `ps.*` types stop here.
  SyncOperation _toSyncOperation(ps.CrudEntry entry) {
    return SyncOperation(
      tableName: entry.table,
      rowId: entry.id,
      type: switch (entry.op) {
        ps.UpdateType.put => SyncOperationType.put,
        ps.UpdateType.patch => SyncOperationType.patch,
        ps.UpdateType.delete => SyncOperationType.delete,
      },
      payload: entry.opData,
    );
  }
}
