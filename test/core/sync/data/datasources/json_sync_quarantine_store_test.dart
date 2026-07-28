import 'dart:convert';

import 'package:billetudo/core/sync/data/datasources/json_sync_quarantine_store.dart';
import 'package:billetudo/core/sync/domain/entities/quarantined_operation.dart';
import 'package:billetudo/core/sync/domain/entities/sync_failure_kind.dart';
import 'package:billetudo/core/sync/domain/entities/sync_operation.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../support/temp_sync_storage_directory.dart';

/// The quarantine is the only copy of a write the cloud rejected. If this file
/// loses a record, the user loses data — which is the whole failure mode the
/// quarantine exists to prevent. So: it must survive a restart, and it must
/// never throw while reading, no matter what is in the file.
void main() {
  late TempSyncStorageDirectory storage;

  setUp(() => storage = TempSyncStorageDirectory.create('quarantine_store'));
  tearDown(() => storage.dispose());

  QuarantinedOperation operation({
    String id = 'q-1',
    String tableName = 'debts',
    String rowId = 'd-1',
    SyncOperationType type = SyncOperationType.put,
    Map<String, dynamic>? payload,
    SyncFailureKind kind = SyncFailureKind.brokenSchema,
    String? errorCode = 'PGRST204',
    int attempts = 1,
    DateTime? at,
  }) {
    final timestamp = at ?? DateTime.utc(2026, 7, 27, 10, 30);
    return QuarantinedOperation(
      id: id,
      operation: SyncOperation(
        tableName: tableName,
        rowId: rowId,
        type: type,
        payload: payload ?? <String, dynamic>{'amount_minor': 1234},
      ),
      kind: kind,
      errorCode: errorCode,
      errorMessage: 'boom',
      quarantinedAt: timestamp,
      updatedAt: timestamp,
      attempts: attempts,
    );
  }

  test('sin archivo, la cuarentena está vacía', () async {
    final store = JsonSyncQuarantineStore(storage);

    expect(await store.readAll(), isEmpty);
  });

  test('lo guardado sobrevive a un reinicio (otra instancia, mismo archivo)',
      () async {
    await JsonSyncQuarantineStore(storage).upsert(operation());

    final reopened = await JsonSyncQuarantineStore(storage).readAll();

    expect(reopened, hasLength(1));
    expect(reopened.single.id, 'q-1');
    expect(reopened.single.operation.tableName, 'debts');
    expect(reopened.single.operation.rowId, 'd-1');
    expect(reopened.single.operation.type, SyncOperationType.put);
    expect(reopened.single.kind, SyncFailureKind.brokenSchema);
    expect(reopened.single.errorCode, 'PGRST204');
    expect(reopened.single.attempts, 1);
    // Dinero: entero en unidades menores, jamás double — ni siquiera después
    // de dar la vuelta por JSON.
    expect(reopened.single.operation.payload!['amount_minor'], 1234);
    expect(reopened.single.operation.payload!['amount_minor'], isA<int>());
  });

  test('el id es UUID en texto, no un autoincrement', () async {
    final store = JsonSyncQuarantineStore(storage);
    await store.upsert(operation(id: '0f4b7a1e-3f2c-4c7f-9d2f-8a1b2c3d4e5f'));

    final stored = (await store.readAll()).single;

    expect(stored.id, isA<String>());
    expect(
      stored.id,
      matches(
        RegExp(
          r'^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$',
        ),
      ),
    );
  });

  test('upsert reemplaza por id en vez de duplicar', () async {
    final store = JsonSyncQuarantineStore(storage);
    await store.upsert(operation());

    await store.upsert(operation(attempts: 5, errorCode: '23503'));

    final stored = await store.readAll();
    expect(stored, hasLength(1));
    expect(stored.single.attempts, 5);
    expect(stored.single.errorCode, '23503');
  });

  test('upsert de otro id agrega un registro nuevo, el más viejo primero',
      () async {
    final store = JsonSyncQuarantineStore(storage);

    await store.upsert(operation());
    await store.upsert(operation(id: 'q-2', tableName: 'transactions'));

    expect(
      (await store.readAll()).map((each) => each.id),
      <String>['q-1', 'q-2'],
    );
  });

  test('remove borra solo el registro pedido, y persiste', () async {
    final store = JsonSyncQuarantineStore(storage);
    await store.upsert(operation());
    await store.upsert(operation(id: 'q-2'));

    await store.remove('q-1');

    expect((await store.readAll()).single.id, 'q-2');
    expect(
      (await JsonSyncQuarantineStore(storage).readAll()).single.id,
      'q-2',
    );
  });

  test('remove de un id inexistente no altera nada', () async {
    final store = JsonSyncQuarantineStore(storage);
    await store.upsert(operation());

    await store.remove('no-existe');

    expect(await store.readAll(), hasLength(1));
  });

  test('removeAll vacía el archivo', () async {
    final store = JsonSyncQuarantineStore(storage);
    await store.upsert(operation());

    await store.removeAll();

    expect(await store.readAll(), isEmpty);
    expect(await JsonSyncQuarantineStore(storage).readAll(), isEmpty);
  });

  test('watchAll emite el contenido actual y luego cada cambio', () async {
    final store = JsonSyncQuarantineStore(storage);
    await store.upsert(operation());

    final emissions = <List<QuarantinedOperation>>[];
    final subscription = store.watchAll().listen(emissions.add);
    await Future<void>.delayed(Duration.zero);
    await store.upsert(operation(id: 'q-2'));
    await store.remove('q-1');
    await Future<void>.delayed(Duration.zero);
    await subscription.cancel();

    expect(emissions.map((each) => each.length), <int>[1, 2, 1]);
    expect(emissions.last.single.id, 'q-2');
  });

  group('un archivo ilegible degrada a vacío en vez de tumbar la app', () {
    test('JSON corrupto (escritura truncada por un crash)', () async {
      storage.writeRaw('quarantine.json', '[{"id": "q-1", "tab');

      expect(await JsonSyncQuarantineStore(storage).readAll(), isEmpty);
    });

    test('archivo vacío', () async {
      storage.writeRaw('quarantine.json', '   ');

      expect(await JsonSyncQuarantineStore(storage).readAll(), isEmpty);
    });

    test('JSON válido pero que no es una lista', () async {
      storage.writeRaw('quarantine.json', '{"id": "q-1"}');

      expect(await JsonSyncQuarantineStore(storage).readAll(), isEmpty);
    });
  });

  group('un registro corrupto se descarta sin arrastrar a los sanos', () {
    test('descarta el que no tiene id/tabla/fila y conserva el resto',
        () async {
      final healthy = <String, dynamic>{
        'id': 'q-2',
        'table': 'debts',
        'row_id': 'd-2',
        'op': 'put',
        'payload': <String, dynamic>{'amount_minor': 999},
        'kind': 'brokenSchema',
        'error_code': 'PGRST204',
        'error_message': 'boom',
        'quarantined_at': '2026-07-27T10:30:00.000Z',
        'updated_at': '2026-07-27T10:30:00.000Z',
        'attempts': 2,
      };
      storage.writeRaw(
        'quarantine.json',
        jsonEncode(<dynamic>[
          <String, dynamic>{'id': 42, 'table': 'debts'}, // id no es String
          <String, dynamic>{'id': 'q-3', 'table': 'debts'}, // sin row_id
          <String, dynamic>{
            'id': 'q-4',
            'table': 'debts',
            'row_id': 'd-4',
            'op': 'explode', // tipo desconocido
            'quarantined_at': '2026-07-27T10:30:00.000Z',
          },
          <String, dynamic>{
            'id': 'q-5',
            'table': 'debts',
            'row_id': 'd-5',
            'op': 'put',
            'quarantined_at': 'no-es-una-fecha',
          },
          'ni siquiera es un objeto',
          healthy,
        ]),
      );

      final stored = await JsonSyncQuarantineStore(storage).readAll();

      expect(stored, hasLength(1));
      expect(stored.single.id, 'q-2');
      expect(stored.single.attempts, 2);
      expect(stored.single.operation.payload!['amount_minor'], 999);
    });

    test('un registro sin campos opcionales toma valores por defecto',
        () async {
      storage.writeRaw(
        'quarantine.json',
        jsonEncode(<dynamic>[
          <String, dynamic>{
            'id': 'q-6',
            'table': 'debts',
            'row_id': 'd-6',
            'op': 'delete',
            'quarantined_at': '2026-07-27T10:30:00.000Z',
          },
        ]),
      );

      final stored = (await JsonSyncQuarantineStore(storage).readAll()).single;

      expect(stored.operation.payload, isNull);
      expect(stored.errorCode, isNull);
      expect(stored.errorMessage, '');
      expect(stored.attempts, 1);
      // Sin `updated_at` cae en `quarantined_at`, nunca en null.
      expect(stored.updatedAt, stored.quarantinedAt);
    });
  });

  test('las fechas se guardan en UTC ISO-8601, no como índice ni epoch local',
      () async {
    await JsonSyncQuarantineStore(storage)
        .upsert(operation(at: DateTime.utc(2026, 7, 27, 10, 30)));

    final raw = jsonDecode(storage.readRaw('quarantine.json')!) as List;
    final record = raw.single as Map<String, dynamic>;

    expect(record['quarantined_at'], '2026-07-27T10:30:00.000Z');
    // Los enums viajan por nombre: reordenarlos no puede reinterpretar lo ya
    // guardado.
    expect(record['op'], 'put');
    expect(record['kind'], 'brokenSchema');
  });
}
