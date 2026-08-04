import 'dart:convert';

import 'package:billetudo/core/sync/data/datasources/json_sync_retry_ledger_store.dart';
import 'package:billetudo/core/sync/data/models/sync_retry_record.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../support/temp_sync_storage_directory.dart';

/// The ledger is the watchdog's memory. An in-memory counter would reset on
/// every app start, and the operation that blocks the FIFO queue survives
/// restarts — so the evidence has to as well, or the 24 h gate could never be
/// reached and the watchdog would be decorative.
///
/// The other half of the contract is that it is *diagnostics*: reading it must
/// never throw, whatever is in the file. A corrupt ledger that took the upload
/// path down would be strictly worse than no ledger.
void main() {
  late TempSyncStorageDirectory storage;

  setUp(() => storage = TempSyncStorageDirectory.create('retry_ledger_store'));
  tearDown(() => storage.dispose());

  SyncRetryRecord record({
    String key = 'debts#d-1#patch',
    int attempts = 3,
    DateTime? firstFailureAt,
    DateTime? lastFailureAt,
    String? code = 'PGRST204',
  }) =>
      SyncRetryRecord(
        key: key,
        attempts: attempts,
        firstFailureAt: firstFailureAt ?? DateTime.utc(2026, 7, 25, 15, 39),
        lastFailureAt: lastFailureAt ?? DateTime.utc(2026, 7, 26, 16, 39),
        lastErrorCode: code,
      );

  List<Map<String, dynamic>> storedJson() =>
      (jsonDecode(storage.readRaw('retries.json')!) as List)
          .cast<Map<String, dynamic>>();

  test('sin archivo, el ledger está vacío', () async {
    expect(await JsonSyncRetryLedgerStore(storage).readAll(), isEmpty);
  });

  test('lo guardado sobrevive a un reinicio (otra instancia, mismo archivo)',
      () async {
    await JsonSyncRetryLedgerStore(storage).upsert(record());

    final reopened = await JsonSyncRetryLedgerStore(storage).readAll();

    expect(reopened, hasLength(1));
    expect(reopened.single.key, 'debts#d-1#patch');
    expect(reopened.single.attempts, 3);
    expect(reopened.single.firstFailureAt, DateTime.utc(2026, 7, 25, 15, 39));
    expect(reopened.single.lastFailureAt, DateTime.utc(2026, 7, 26, 16, 39));
    expect(reopened.single.lastErrorCode, 'PGRST204');
    // Y con eso, la compuerta de 24 h se puede evaluar tras el reinicio.
    expect(reopened.single.stuckFor, const Duration(hours: 25));
  });

  test('las fechas se persisten en UTC ISO-8601', () async {
    await JsonSyncRetryLedgerStore(storage).upsert(
      record(firstFailureAt: DateTime.utc(2026, 7, 25, 15, 39).toLocal()),
    );

    final json = storedJson().single;
    expect(json['first_failure_at'], '2026-07-25T15:39:00.000Z');
    expect(json['key'], 'debts#d-1#patch');
    expect(json['attempts'], 3);
  });

  test('upsert reemplaza por clave en vez de duplicar', () async {
    final store = JsonSyncRetryLedgerStore(storage);
    await store.upsert(record(attempts: 3));

    await store.upsert(record(attempts: 4, code: 'WEIRD'));

    final stored = await store.readAll();
    expect(stored, hasLength(1));
    expect(stored.single.attempts, 4);
    expect(stored.single.lastErrorCode, 'WEIRD');
  });

  test('claves distintas conviven', () async {
    final store = JsonSyncRetryLedgerStore(storage);

    await store.upsert(record());
    await store.upsert(record(key: 'debts#d-1#delete'));
    await store.upsert(record(key: 'goals#g-1#put'));

    expect(
      (await store.readAll()).map((each) => each.key),
      containsAll(
          <String>['debts#d-1#patch', 'debts#d-1#delete', 'goals#g-1#put']),
    );
  });

  test('remove borra solo esa clave y persiste el borrado', () async {
    final store = JsonSyncRetryLedgerStore(storage);
    await store.upsert(record());
    await store.upsert(record(key: 'goals#g-1#put'));

    await store.remove('debts#d-1#patch');

    expect(
      (await JsonSyncRetryLedgerStore(storage).readAll()).single.key,
      'goals#g-1#put',
    );
  });

  test('remove de una clave inexistente no altera nada', () async {
    final store = JsonSyncRetryLedgerStore(storage);
    await store.upsert(record());

    await store.remove('no-existe');

    expect(await store.readAll(), hasLength(1));
  });

  test('removeAll deja el archivo vacío, no borrado', () async {
    final store = JsonSyncRetryLedgerStore(storage);
    await store.upsert(record());

    await store.removeAll();

    expect(await store.readAll(), isEmpty);
    expect(storage.readRaw('retries.json'), '[]');
  });

  test('la lista devuelta es inmodificable (el caché no se puede corromper)',
      () async {
    final store = JsonSyncRetryLedgerStore(storage);
    await store.upsert(record());

    final stored = await store.readAll();

    expect(stored.clear, throwsUnsupportedError);
    expect(await store.readAll(), hasLength(1));
  });

  group('un archivo ilegible degrada a vacío, nunca lanza', () {
    for (final contents in <String>['{no json', '{"key": "x"}', '', '   ']) {
      test('contenido ${jsonEncode(contents)} se lee como ledger vacío',
          () async {
        storage.writeRaw('retries.json', contents);

        expect(await JsonSyncRetryLedgerStore(storage).readAll(), isEmpty);
      });
    }

    test('un registro roto se descarta y los válidos sobreviven', () async {
      storage.writeRaw(
        'retries.json',
        jsonEncode(<Map<String, dynamic>>[
          // Sin clave: irrecuperable.
          <String, dynamic>{'attempts': 5},
          // Sin fecha del primer fallo: la compuerta de tiempo no se podría
          // evaluar, así que el registro no sirve.
          <String, dynamic>{'key': 'debts#d-2#put', 'attempts': 5},
          record().toJson(),
        ]),
      );

      final stored = await JsonSyncRetryLedgerStore(storage).readAll();

      expect(stored.map((each) => each.key), <String>['debts#d-1#patch']);
    });

    test('un registro sin last_failure_at cae en first_failure_at', () async {
      storage.writeRaw(
        'retries.json',
        jsonEncode(<Map<String, dynamic>>[
          <String, dynamic>{
            'key': 'debts#d-1#patch',
            'attempts': 'muchos',
            'first_failure_at': '2026-07-25T15:39:00.000Z',
          },
        ]),
      );

      final stored = (await JsonSyncRetryLedgerStore(storage).readAll()).single;

      expect(stored.lastFailureAt, stored.firstFailureAt);
      expect(stored.stuckFor, Duration.zero);
      // `attempts` ilegible cuenta como un intento: nunca como cero, que
      // reiniciaría la cuenta de un atasco real.
      expect(stored.attempts, 1);
      expect(stored.lastErrorCode, isNull);
    });
  });
}
