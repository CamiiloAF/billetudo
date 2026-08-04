import 'package:billetudo/core/sync/data/datasources/sync_retry_ledger_store.dart';
import 'package:billetudo/core/sync/data/models/sync_retry_record.dart';

/// In-memory [SyncRetryLedgerStore] with injectable I/O failures.
///
/// The persistence of the ledger is covered against the real file in
/// `json_sync_retry_ledger_store_test.dart`; here the store only has to
/// remember records within a test, and — for the watchdog's fail-open
/// contract — to be able to break on demand.
class FakeSyncRetryLedgerStore implements SyncRetryLedgerStore {
  final Map<String, SyncRetryRecord> records = <String, SyncRetryRecord>{};

  /// Thrown by the matching method when set. `Exception` rather than `Object`
  /// so tests do not have to silence `only_throw_errors`.
  Exception? readError;
  Exception? upsertError;
  Exception? removeError;

  int removeCalls = 0;

  /// Pre-existing history, as a restart would find it on disk.
  void seed(SyncRetryRecord record) => records[record.key] = record;

  SyncRetryRecord? recordFor(String key) => records[key];

  @override
  Future<List<SyncRetryRecord>> readAll() async {
    if (readError case final error?) {
      throw error;
    }
    return records.values.toList();
  }

  @override
  Future<void> upsert(SyncRetryRecord record) async {
    if (upsertError case final error?) {
      throw error;
    }
    records[record.key] = record;
  }

  @override
  Future<void> remove(String key) async {
    removeCalls++;
    if (removeError case final error?) {
      throw error;
    }
    records.remove(key);
  }

  @override
  Future<void> removeAll() async => records.clear();
}
