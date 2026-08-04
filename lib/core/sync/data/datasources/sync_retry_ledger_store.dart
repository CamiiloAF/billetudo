import '../models/sync_retry_record.dart';

/// Persistence port for the retry ledger the watchdog keeps.
///
/// As narrow as `SyncQuarantineStore`: the thresholds and the verdict live in
/// `SyncRetryWatchdog`, this only keeps rows alive across restarts.
abstract class SyncRetryLedgerStore {
  /// Every tracked operation, in no particular order.
  Future<List<SyncRetryRecord>> readAll();

  /// Inserts or replaces a record by [SyncRetryRecord.key].
  Future<void> upsert(SyncRetryRecord record);

  Future<void> remove(String key);

  Future<void> removeAll();
}
