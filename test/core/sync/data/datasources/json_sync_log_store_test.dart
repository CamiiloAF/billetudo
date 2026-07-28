import 'dart:convert';

import 'package:billetudo/core/sync/data/datasources/json_sync_log_store.dart';
import 'package:billetudo/core/sync/domain/entities/sync_log_entry.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../support/temp_sync_storage_directory.dart';

/// The on-device log is the symptom a blocked upload queue never had: for
/// three days the only trace of the `PGRST204` loop lived in Sentry, which is
/// unreachable from the device and absent without a DSN. So it has to survive
/// restarts, stay bounded, and never crash the app while being read.
void main() {
  late TempSyncStorageDirectory storage;

  setUp(() => storage = TempSyncStorageDirectory.create('sync_log_store'));
  tearDown(() => storage.dispose());

  SyncLogEntry entry({
    String id = 'l-1',
    SyncLogLevel level = SyncLogLevel.info,
    SyncLogEvent event = SyncLogEvent.uploadStarted,
    String message = 'uploading 1 operation(s)',
    String? code,
    String? tableName,
    DateTime? at,
  }) {
    return SyncLogEntry(
      id: id,
      timestamp: at ?? DateTime.utc(2026, 7, 27, 10, 30),
      level: level,
      event: event,
      message: message,
      code: code,
      tableName: tableName,
    );
  }

  test('sin archivo, el log está vacío', () async {
    expect(await JsonSyncLogStore(storage).readAll(), isEmpty);
  });

  test('lo escrito sobrevive a un reinicio, con todos sus campos', () async {
    await JsonSyncLogStore(storage).append(
      entry(
        level: SyncLogLevel.error,
        event: SyncLogEvent.quarantined,
        message: 'brokenSchema rejection, operation quarantined',
        code: 'PGRST204',
        tableName: 'debts',
      ),
    );

    final stored = (await JsonSyncLogStore(storage).readAll()).single;

    expect(stored.id, 'l-1');
    expect(stored.level, SyncLogLevel.error);
    expect(stored.event, SyncLogEvent.quarantined);
    expect(stored.code, 'PGRST204');
    expect(stored.tableName, 'debts');
    expect(stored.timestamp, DateTime.utc(2026, 7, 27, 10, 30));
  });

  test('append conserva el orden: el más viejo primero', () async {
    final store = JsonSyncLogStore(storage);

    await store.append(entry(id: 'l-1'));
    await store.append(entry(id: 'l-2'));
    await store.append(entry(id: 'l-3'));

    expect(
      (await store.readAll()).map((each) => each.id),
      <String>['l-1', 'l-2', 'l-3'],
    );
  });

  group('ring buffer de ${JsonSyncLogStore.maxEntries}', () {
    test('en el límite exacto no descarta nada', () async {
      final store = JsonSyncLogStore(storage);
      for (var i = 0; i < JsonSyncLogStore.maxEntries; i++) {
        await store.append(entry(id: 'l-$i'));
      }

      final stored = await store.readAll();

      expect(stored, hasLength(JsonSyncLogStore.maxEntries));
      expect(stored.first.id, 'l-0');
      expect(stored.last.id, 'l-${JsonSyncLogStore.maxEntries - 1}');
    });

    test('pasado el límite descarta las más viejas y conserva las últimas 200',
        () async {
      final store = JsonSyncLogStore(storage);
      const total = JsonSyncLogStore.maxEntries + 25;
      for (var i = 0; i < total; i++) {
        await store.append(entry(id: 'l-$i'));
      }

      final stored = await store.readAll();

      expect(stored, hasLength(JsonSyncLogStore.maxEntries));
      expect(stored.first.id, 'l-25');
      expect(stored.last.id, 'l-${total - 1}');
      // Y el recorte también quedó en disco: el archivo no crece sin límite.
      final onDisk = jsonDecode(storage.readRaw('sync_log.json')!) as List;
      expect(onDisk, hasLength(JsonSyncLogStore.maxEntries));
    });

    test(
        'un archivo que ya venía con más de 200 se recorta al siguiente '
        'append', () async {
      storage.writeRaw(
        'sync_log.json',
        jsonEncode(<dynamic>[
          for (var i = 0; i < 250; i++)
            <String, dynamic>{
              'id': 'old-$i',
              'at': '2026-07-27T10:30:00.000Z',
              'level': 'info',
              'event': 'uploadStarted',
              'message': 'x',
            },
        ]),
      );
      final store = JsonSyncLogStore(storage);

      await store.append(entry(id: 'nuevo'));

      final stored = await store.readAll();
      expect(stored, hasLength(JsonSyncLogStore.maxEntries));
      expect(stored.last.id, 'nuevo');
      expect(stored.first.id, 'old-51');
    });
  });

  test('removeAll deja el log vacío, también en disco', () async {
    final store = JsonSyncLogStore(storage);
    await store.append(entry());

    await store.removeAll();

    expect(await store.readAll(), isEmpty);
    expect(await JsonSyncLogStore(storage).readAll(), isEmpty);
  });

  test('watchAll emite el contenido actual y luego cada append', () async {
    final store = JsonSyncLogStore(storage);
    await store.append(entry(id: 'l-1'));

    final emissions = <List<SyncLogEntry>>[];
    final subscription = store.watchAll().listen(emissions.add);
    await Future<void>.delayed(Duration.zero);
    await store.append(entry(id: 'l-2'));
    await Future<void>.delayed(Duration.zero);
    await subscription.cancel();

    expect(emissions.map((each) => each.length), <int>[1, 2]);
    expect(emissions.last.last.id, 'l-2');
  });

  group('un archivo ilegible degrada a vacío en vez de tumbar la app', () {
    test('JSON corrupto', () async {
      storage.writeRaw('sync_log.json', '[{"id": "l-1", "at');

      expect(await JsonSyncLogStore(storage).readAll(), isEmpty);
    });

    test('JSON válido que no es una lista', () async {
      storage.writeRaw('sync_log.json', '"solo un string"');

      expect(await JsonSyncLogStore(storage).readAll(), isEmpty);
    });
  });

  test('un registro corrupto se descarta y los sanos sobreviven', () async {
    storage.writeRaw(
      'sync_log.json',
      jsonEncode(<dynamic>[
        <String, dynamic>{'id': 'sin-fecha', 'event': 'uploadStarted'},
        <String, dynamic>{'id': 'sin-evento', 'at': '2026-07-27T10:30:00.000Z'},
        <String, dynamic>{
          'id': 'evento-desconocido',
          'at': '2026-07-27T10:30:00.000Z',
          'event': 'inventado',
        },
        <String, dynamic>{
          'id': 'sano',
          'at': '2026-07-27T10:30:00.000Z',
          'level': 'nivel-inventado',
          'event': 'quarantined',
          'message': 'boom',
          'code': 'PGRST204',
          'table': 'debts',
        },
      ]),
    );

    final stored = await JsonSyncLogStore(storage).readAll();

    expect(stored, hasLength(1));
    expect(stored.single.id, 'sano');
    // Un nivel desconocido cae en `info`, nunca tumba la lectura.
    expect(stored.single.level, SyncLogLevel.info);
    expect(stored.single.event, SyncLogEvent.quarantined);
  });

  test('toLogLine arma una línea con fecha UTC, nivel, evento, tabla y código',
      () {
    final line = entry(
      level: SyncLogLevel.error,
      event: SyncLogEvent.quarantined,
      message: 'operation quarantined',
      code: 'PGRST204',
      tableName: 'debts',
    ).toLogLine();

    expect(
      line,
      '2026-07-27T10:30:00.000Z [ERROR] quarantined table=debts '
      'code=PGRST204 — operation quarantined',
    );
  });

  test('el archivo guarda enums por nombre y fechas en UTC ISO-8601', () async {
    await JsonSyncLogStore(storage).append(
      entry(level: SyncLogLevel.warning, event: SyncLogEvent.uploadRetry),
    );

    final raw = jsonDecode(storage.readRaw('sync_log.json')!) as List;
    final record = raw.single as Map<String, dynamic>;

    expect(record['level'], 'warning');
    expect(record['event'], 'uploadRetry');
    expect(record['at'], '2026-07-27T10:30:00.000Z');
  });
}
