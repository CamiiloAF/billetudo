import 'dart:async';

import 'package:injectable/injectable.dart';

import '../../domain/entities/sync_log_entry.dart';
import '../models/sync_log_entry_dto.dart';
import 'json_list_file.dart';
import 'sync_log_store.dart';
import 'sync_storage_directory.dart';

/// [SyncLogStore] backed by `<app documents>/sync/sync_log.json`, capped at
/// [maxEntries].
///
/// The cap is what makes an always-on log affordable: the file stays a few
/// tens of kilobytes no matter how long the app runs, so rewriting it on each
/// append costs nothing measurable and needs no rotation policy.
@LazySingleton(as: SyncLogStore)
class JsonSyncLogStore implements SyncLogStore {
  JsonSyncLogStore(SyncStorageDirectory directory)
      : _file = JsonListFile(directory, 'sync_log.json');

  /// Ring buffer bound. Enough to cover a full upload cycle with its errors
  /// without turning into an unbounded file.
  static const int maxEntries = 200;

  final JsonListFile _file;

  final StreamController<List<SyncLogEntry>> _changes =
      StreamController<List<SyncLogEntry>>.broadcast();

  List<SyncLogEntry>? _cache;

  Future<List<SyncLogEntry>> _load() async {
    final cached = _cache;
    if (cached != null) {
      return cached;
    }
    final rows = await _file.read();
    final parsed =
        rows.map(SyncLogEntryDto.fromJson).whereType<SyncLogEntry>().toList();
    _cache = parsed;
    return parsed;
  }

  Future<void> _persist(List<SyncLogEntry> entries) async {
    _cache = entries;
    _changes.add(List<SyncLogEntry>.unmodifiable(entries));
    await _file.write(entries.map(SyncLogEntryDto.toJson).toList());
  }

  @override
  Future<List<SyncLogEntry>> readAll() async =>
      List<SyncLogEntry>.unmodifiable(await _load());

  @override
  Stream<List<SyncLogEntry>> watchAll() async* {
    yield await readAll();
    yield* _changes.stream;
  }

  @override
  Future<void> append(SyncLogEntry entry) async {
    final entries = List<SyncLogEntry>.from(await _load())..add(entry);
    if (entries.length > maxEntries) {
      entries.removeRange(0, entries.length - maxEntries);
    }
    await _persist(entries);
  }

  @override
  Future<void> removeAll() async => _persist(const <SyncLogEntry>[]);
}
