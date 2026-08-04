import '../../../error/result.dart';
import '../entities/sync_log_entry.dart';

/// Bounded, on-device log of what the sync engine has been doing.
///
/// Exists so a stuck upload queue has a symptom somewhere reachable from the
/// device, instead of only in a crash reporter that may not even be enabled.
abstract class SyncLogRepository {
  /// Appends an entry. Id and timestamp are stamped by the implementation.
  ///
  /// Never throws and never fails: it is called from the upload path, where a
  /// logging error must not be mistaken for an upload error.
  Future<void> record({
    required SyncLogEvent event,
    required String message,
    SyncLogLevel level = SyncLogLevel.info,
    String? code,
    String? tableName,
  });

  /// Emits the current log right away, then on every append. Newest first.
  Stream<List<SyncLogEntry>> watchEntries();

  /// Reads the log once. Newest first.
  FutureResult<List<SyncLogEntry>> getEntries();

  /// Renders the whole log as plain text, oldest first, for sharing.
  FutureResult<String> exportAsText();

  /// Empties the log.
  FutureResult<Unit> clear();
}
