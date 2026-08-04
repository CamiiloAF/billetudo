import '../../domain/entities/sync_log_entry.dart';

/// Persistence port for the local sync log. The ring buffer bound lives in
/// the implementation.
abstract class SyncLogStore {
  /// Stored entries, oldest first.
  Future<List<SyncLogEntry>> readAll();

  /// Current contents, then every change. Oldest first.
  Stream<List<SyncLogEntry>> watchAll();

  /// Appends an entry, evicting the oldest one past the buffer bound.
  Future<void> append(SyncLogEntry entry);

  Future<void> removeAll();
}
