import '../../domain/entities/sync_operation.dart';

/// Replays a single [SyncOperation] against the cloud database.
///
/// One implementation, two callers: the PowerSync upload path (first attempt)
/// and the quarantine (manual retry). They must go through the exact same
/// code, or a retry would write something subtly different from what the
/// original attempt tried to write.
abstract class SyncOperationUploader {
  /// Throws the backend exception as is; classifying it is the caller's job
  /// (see `SyncErrorClassifier`).
  Future<void> upload(SyncOperation operation);
}
