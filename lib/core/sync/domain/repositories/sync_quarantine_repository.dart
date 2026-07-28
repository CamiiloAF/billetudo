import '../../../error/result.dart';
import '../entities/quarantined_operation.dart';
import '../entities/sync_failure_kind.dart';
import '../entities/sync_operation.dart';

/// Local holding area for writes the cloud rejected permanently.
///
/// Contract, in order of importance:
///  1. Nothing is ever discarded silently — a quarantined write survives app
///     restarts until the user retries it or discards it explicitly.
///  2. Quarantining a write must never throw: it runs inside the upload path,
///     where an exception would be read as "transient" and would put the queue
///     right back into the loop this exists to prevent. Hence [record] returns
///     `Future<void>` and swallows its own storage errors (reporting them).
abstract class SyncQuarantineRepository {
  /// Stores a failed write. The record's id, timestamps and attempt counter
  /// are stamped by the implementation.
  Future<void> record({
    required SyncOperation operation,
    required SyncFailureKind kind,
    required String errorMessage,
    String? errorCode,
  });

  /// Emits the current quarantine right away, then on every change.
  Stream<List<QuarantinedOperation>> watchFailures();

  /// Reads the quarantine once.
  FutureResult<List<QuarantinedOperation>> getFailures();

  /// Replays one quarantined write against the cloud. On success the record is
  /// removed; on failure `attempts` is bumped and it stays quarantined.
  FutureResult<Unit> retry(String id);

  /// Replays every quarantined write. Returns how many succeeded.
  FutureResult<int> retryAll();

  /// Drops one record without replaying it (explicit user decision).
  FutureResult<Unit> clear(String id);

  /// Drops every record without replaying them.
  FutureResult<Unit> clearAll();
}
