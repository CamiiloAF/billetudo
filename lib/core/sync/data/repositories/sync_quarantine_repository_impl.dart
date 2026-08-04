import 'package:injectable/injectable.dart';
import 'package:uuid/uuid.dart';

import '../../../crash/crash_reporter.dart';
import '../../../error/result.dart';
import '../../domain/entities/quarantined_operation.dart';
import '../../domain/entities/sync_failure_kind.dart';
import '../../domain/entities/sync_log_entry.dart';
import '../../domain/entities/sync_operation.dart';
import '../../domain/repositories/sync_log_repository.dart';
import '../../domain/repositories/sync_quarantine_repository.dart';
import '../datasources/sync_error_classifier.dart';
import '../datasources/sync_operation_uploader.dart';
import '../datasources/sync_quarantine_store.dart';

const _uuid = Uuid();

/// Holds permanently-rejected writes locally and replays them on demand.
@LazySingleton(as: SyncQuarantineRepository)
class SyncQuarantineRepositoryImpl implements SyncQuarantineRepository {
  const SyncQuarantineRepositoryImpl(
    this._store,
    this._uploader,
    this._log,
    this._crash,
  );

  final SyncQuarantineStore _store;
  final SyncOperationUploader _uploader;
  final SyncLogRepository _log;
  final CrashReporter _crash;

  @override
  Future<void> record({
    required SyncOperation operation,
    required SyncFailureKind kind,
    required String errorMessage,
    String? errorCode,
  }) async {
    try {
      final now = DateTime.now();
      // Same row + same kind of write = the same problem, not a new one. If it
      // failed again (a later transaction touching the same row), bump the
      // counter and keep the newest payload instead of growing the list.
      final existing = _firstWhereOrNull(
        await _store.readAll(),
        (each) =>
            each.operation.tableName == operation.tableName &&
            each.operation.rowId == operation.rowId &&
            each.operation.type == operation.type,
      );

      await _store.upsert(
        QuarantinedOperation(
          id: existing?.id ?? _uuid.v4(),
          operation: operation,
          kind: kind,
          errorCode: errorCode,
          errorMessage: errorMessage,
          quarantinedAt: existing?.quarantinedAt ?? now,
          updatedAt: now,
          attempts: (existing?.attempts ?? 0) + 1,
        ),
      );
    } catch (e, st) {
      // Never throw from here: this runs inside the upload path, where an
      // exception would be classified as transient and would put the queue
      // back into the infinite-retry loop the quarantine exists to break.
      await _crash.recordError(
        e,
        st,
        context: 'sync quarantine could not store a rejected '
            '${operation.type.name} on ${operation.tableName}',
        fatal: true,
      );
    }
  }

  @override
  Stream<List<QuarantinedOperation>> watchFailures() => _store.watchAll();

  @override
  FutureResult<List<QuarantinedOperation>> getFailures() async {
    try {
      return Right(await _store.readAll());
    } catch (e, st) {
      return Left(
        DatabaseFailure(
          'could not read the sync quarantine',
          cause: e,
          stackTrace: st,
        ),
      );
    }
  }

  @override
  FutureResult<Unit> retry(String id) async {
    final List<QuarantinedOperation> operations;
    try {
      operations = await _store.readAll();
    } catch (e, st) {
      return Left(
        DatabaseFailure(
          'could not read the sync quarantine',
          cause: e,
          stackTrace: st,
        ),
      );
    }
    final target = _firstWhereOrNull(operations, (each) => each.id == id);
    if (target == null) {
      return const Left(NotFoundFailure('quarantined operation not found'));
    }
    return _replay(target);
  }

  @override
  FutureResult<int> retryAll() async {
    final List<QuarantinedOperation> operations;
    try {
      operations = await _store.readAll();
    } catch (e, st) {
      return Left(
        DatabaseFailure(
          'could not read the sync quarantine',
          cause: e,
          stackTrace: st,
        ),
      );
    }
    var recovered = 0;
    for (final operation in operations) {
      final result = await _replay(operation);
      if (result.isRight()) {
        recovered++;
      }
    }
    return Right(recovered);
  }

  @override
  FutureResult<Unit> clear(String id) async {
    try {
      await _store.remove(id);
      await _log.record(
        event: SyncLogEvent.quarantineDiscarded,
        level: SyncLogLevel.warning,
        message: 'discarded by user',
      );
      return const Right(unit);
    } catch (e, st) {
      return Left(
        DatabaseFailure(
          'could not discard the quarantined operation',
          cause: e,
          stackTrace: st,
        ),
      );
    }
  }

  @override
  FutureResult<Unit> clearAll() async {
    try {
      await _store.removeAll();
      await _log.record(
        event: SyncLogEvent.quarantineDiscarded,
        level: SyncLogLevel.warning,
        message: 'quarantine cleared by user',
      );
      return const Right(unit);
    } catch (e, st) {
      return Left(
        DatabaseFailure(
          'could not empty the sync quarantine',
          cause: e,
          stackTrace: st,
        ),
      );
    }
  }

  /// `package:collection`'s `firstWhereOrNull` is not a direct dependency of
  /// this project, and a `firstWhere` with `orElse` cannot return null for a
  /// non-nullable element type.
  QuarantinedOperation? _firstWhereOrNull(
    List<QuarantinedOperation> operations,
    bool Function(QuarantinedOperation) test,
  ) {
    for (final operation in operations) {
      if (test(operation)) {
        return operation;
      }
    }
    return null;
  }

  /// Re-injects one operation. On success it leaves the quarantine; on failure
  /// it stays, with `attempts` bumped and the newest error attached — a retry
  /// never loses the record.
  FutureResult<Unit> _replay(QuarantinedOperation operation) async {
    try {
      await _uploader.upload(operation.operation);
      await _store.remove(operation.id);
      // `tableName:` already prepends the table to the log line — repeating
      // it in the message is what made this the longest line in the block.
      await _log.record(
        event: SyncLogEvent.quarantineRetry,
        message: 'retry ok',
        tableName: operation.operation.tableName,
      );
      return const Right(unit);
    } catch (e, st) {
      final kind = SyncErrorClassifier.classify(e);
      final code = SyncErrorClassifier.codeOf(e);
      await _store.upsert(
        operation.copyWith(
          // A retry that now fails transiently (offline) must not be recorded
          // as a permanent rejection: keep the previous verdict in that case.
          kind: kind.isPermanent ? kind : operation.kind,
          errorCode: code,
          errorMessage: e.toString(),
          updatedAt: DateTime.now(),
          attempts: operation.attempts + 1,
        ),
      );
      await _log.record(
        event: SyncLogEvent.quarantineRetry,
        level: SyncLogLevel.error,
        message: 'retry failed',
        code: code,
        tableName: operation.operation.tableName,
      );
      return Left(
        NetworkFailure(
          'quarantined operation could not be uploaded',
          cause: e,
          stackTrace: st,
        ),
      );
    }
  }
}
