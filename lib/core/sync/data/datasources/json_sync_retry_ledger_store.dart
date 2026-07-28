import 'package:injectable/injectable.dart';

import '../models/sync_retry_record.dart';
import 'json_list_file.dart';
import 'sync_retry_ledger_store.dart';
import 'sync_storage_directory.dart';

/// [SyncRetryLedgerStore] backed by `<app documents>/sync/retries.json`.
///
/// Same file-based storage as the quarantine, and for the same reasons — see
/// `AppDocumentsSyncStorageDirectory`: writing this through the app database
/// would turn the record of a failed upload into another upload.
@LazySingleton(as: SyncRetryLedgerStore)
class JsonSyncRetryLedgerStore implements SyncRetryLedgerStore {
  JsonSyncRetryLedgerStore(SyncStorageDirectory directory)
      : _file = JsonListFile(directory, 'retries.json');

  final JsonListFile _file;

  /// Read once and kept in memory: this is touched on every failed operation
  /// of every batch, and must not cost a file read per operation.
  List<SyncRetryRecord>? _cache;

  Future<List<SyncRetryRecord>> _load() async {
    final cached = _cache;
    if (cached != null) {
      return cached;
    }
    final parsed = (await _file.read())
        .map(SyncRetryRecord.fromJson)
        .whereType<SyncRetryRecord>()
        .toList();
    _cache = parsed;
    return parsed;
  }

  Future<void> _persist(List<SyncRetryRecord> records) async {
    _cache = records;
    await _file.write(records.map((record) => record.toJson()).toList());
  }

  @override
  Future<List<SyncRetryRecord>> readAll() async =>
      List<SyncRetryRecord>.unmodifiable(await _load());

  @override
  Future<void> upsert(SyncRetryRecord record) async {
    final records = List<SyncRetryRecord>.from(await _load());
    final index = records.indexWhere((each) => each.key == record.key);
    if (index >= 0) {
      records[index] = record;
    } else {
      records.add(record);
    }
    await _persist(records);
  }

  @override
  Future<void> remove(String key) async {
    final records = List<SyncRetryRecord>.from(await _load())
      ..removeWhere((each) => each.key == key);
    await _persist(records);
  }

  @override
  Future<void> removeAll() async => _persist(const <SyncRetryRecord>[]);
}
