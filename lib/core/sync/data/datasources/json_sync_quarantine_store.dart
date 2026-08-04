import 'dart:async';

import 'package:injectable/injectable.dart';

import '../../domain/entities/quarantined_operation.dart';
import '../models/quarantined_operation_dto.dart';
import 'json_list_file.dart';
import 'sync_quarantine_store.dart';
import 'sync_storage_directory.dart';

/// [SyncQuarantineStore] backed by `<app documents>/sync/quarantine.json`.
///
/// See [AppDocumentsSyncStorageDirectory] for why this does not live in the
/// app database.
@LazySingleton(as: SyncQuarantineStore)
class JsonSyncQuarantineStore implements SyncQuarantineStore {
  JsonSyncQuarantineStore(SyncStorageDirectory directory)
      : _file = JsonListFile(directory, 'quarantine.json');

  final JsonListFile _file;

  final StreamController<List<QuarantinedOperation>> _changes =
      StreamController<List<QuarantinedOperation>>.broadcast();

  /// Loaded once and kept in memory: the upload path reads it on every failed
  /// operation and must not pay a file read per op.
  List<QuarantinedOperation>? _cache;

  Future<List<QuarantinedOperation>> _load() async {
    final cached = _cache;
    if (cached != null) {
      return cached;
    }
    final rows = await _file.read();
    final parsed = rows
        .map(QuarantinedOperationDto.fromJson)
        .whereType<QuarantinedOperation>()
        .toList();
    _cache = parsed;
    return parsed;
  }

  Future<void> _persist(List<QuarantinedOperation> operations) async {
    _cache = operations;
    _changes.add(List<QuarantinedOperation>.unmodifiable(operations));
    await _file.write(operations.map(QuarantinedOperationDto.toJson).toList());
  }

  @override
  Future<List<QuarantinedOperation>> readAll() async =>
      List<QuarantinedOperation>.unmodifiable(await _load());

  @override
  Stream<List<QuarantinedOperation>> watchAll() async* {
    yield await readAll();
    yield* _changes.stream;
  }

  @override
  Future<void> upsert(QuarantinedOperation operation) async {
    final operations = List<QuarantinedOperation>.from(await _load());
    final index = operations.indexWhere((each) => each.id == operation.id);
    if (index >= 0) {
      operations[index] = operation;
    } else {
      operations.add(operation);
    }
    await _persist(operations);
  }

  @override
  Future<void> remove(String id) async {
    final operations = List<QuarantinedOperation>.from(await _load())
      ..removeWhere((each) => each.id == id);
    await _persist(operations);
  }

  @override
  Future<void> removeAll() async => _persist(const <QuarantinedOperation>[]);
}
