import 'package:injectable/injectable.dart';
import 'package:uuid/uuid.dart';

import '../../../crash/crash_reporter.dart';
import '../../../error/result.dart';
import '../../domain/entities/sync_log_entry.dart';
import '../../domain/repositories/sync_log_repository.dart';
import '../datasources/sync_log_store.dart';

const _uuid = Uuid();

/// Writes the on-device sync log through [SyncLogStore].
///
/// Entries are exposed newest first (what a diagnostics screen wants) but
/// stored and exported oldest first (what reading a trace wants).
@LazySingleton(as: SyncLogRepository)
class SyncLogRepositoryImpl implements SyncLogRepository {
  const SyncLogRepositoryImpl(this._store, this._crash);

  final SyncLogStore _store;
  final CrashReporter _crash;

  @override
  Future<void> record({
    required SyncLogEvent event,
    required String message,
    SyncLogLevel level = SyncLogLevel.info,
    String? code,
    String? tableName,
  }) async {
    try {
      await _store.append(
        SyncLogEntry(
          id: _uuid.v4(),
          timestamp: DateTime.now(),
          level: level,
          event: event,
          message: message,
          code: code,
          tableName: tableName,
        ),
      );
    } catch (e, st) {
      // Logging must never fail its caller: the upload path reads any
      // exception as "the write failed", and a failed *log* would be
      // misclassified as a failed upload.
      await _crash.recordError(e, st, context: 'sync log append failed');
    }
  }

  @override
  Stream<List<SyncLogEntry>> watchEntries() =>
      _store.watchAll().map(_newestFirst);

  @override
  FutureResult<List<SyncLogEntry>> getEntries() async {
    try {
      return Right(_newestFirst(await _store.readAll()));
    } catch (e, st) {
      return Left(
        DatabaseFailure('could not read the sync log',
            cause: e, stackTrace: st),
      );
    }
  }

  @override
  FutureResult<String> exportAsText() async {
    try {
      final entries = await _store.readAll();
      return Right(entries.map((entry) => entry.toLogLine()).join('\n'));
    } catch (e, st) {
      return Left(
        DatabaseFailure(
          'could not export the sync log',
          cause: e,
          stackTrace: st,
        ),
      );
    }
  }

  @override
  FutureResult<Unit> clear() async {
    try {
      await _store.removeAll();
      return const Right(unit);
    } catch (e, st) {
      return Left(
        DatabaseFailure(
          'could not clear the sync log',
          cause: e,
          stackTrace: st,
        ),
      );
    }
  }

  List<SyncLogEntry> _newestFirst(List<SyncLogEntry> entries) =>
      entries.reversed.toList();
}
