import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:billetudo/core/sync/data/datasources/sync_retry_watchdog.dart';
import 'package:billetudo/core/sync/data/models/sync_retry_record.dart';
import 'package:billetudo/core/sync/domain/entities/sync_operation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../support/fake_sync_retry_ledger_store.dart';

/// The watchdog is the last thing standing between an error code nobody
/// foresaw and a repeat of the 2026-07-25 incident: a single write rejected
/// forever, a FIFO queue frozen behind it for three days, 89 changes lost on
/// reinstall. `SyncErrorClassifier` closes the failure modes we know by name;
/// this closes the ones we do not.
///
/// Its two gates exist because the naive "quarantine after N retries" fails
/// worse than the bug: a user on a plane, or a backend down for an afternoon,
/// accumulates perfectly legitimate retries and would watch their writes
/// pulled out of the queue as if something were broken. So every test below is
/// really asking one of two questions — *does a real blockage get caught* and
/// *does a normal outage stay untouched*.
///
/// No fake clock is needed: the ledger is an interface, so "this has been
/// failing for a day" is expressed by seeding a record with an old
/// `firstFailureAt`.
void main() {
  late FakeSyncRetryLedgerStore ledger;
  late SyncRetryWatchdog watchdog;

  setUp(() {
    ledger = FakeSyncRetryLedgerStore();
    watchdog = SyncRetryWatchdog(ledger);
  });

  SyncOperation operation({
    String tableName = 'debts',
    String rowId = 'd-1',
    SyncOperationType type = SyncOperationType.patch,
  }) =>
      SyncOperation(tableName: tableName, rowId: rowId, type: type);

  /// Pre-existing history for [target]: [attempts] counted failures whose
  /// first one happened [age] ago.
  SyncRetryRecord seedHistory({
    required SyncOperation target,
    required int attempts,
    required Duration age,
    String? code,
  }) {
    final now = DateTime.now();
    final record = SyncRetryRecord(
      key: SyncRetryRecord.keyOf(target),
      attempts: attempts,
      firstFailureAt: now.subtract(age),
      lastFailureAt: now,
      lastErrorCode: code,
    );
    ledger.seed(record);
    return record;
  }

  /// A rejection the classifier has no name for: the backend answered, we do
  /// not know what it meant. Exactly the shape of the incident.
  const unknownRejection = PostgrestException(
    message: 'something nobody foresaw',
    code: 'WEIRD-CODE',
  );

  group('las dos compuertas (20 fallos contados Y 24 h)', () {
    test('el primer fallo cuenta 1 y no cuarentena nada', () async {
      final verdict = await watchdog.registerFailure(
        operation: operation(),
        error: unknownRejection,
      );

      expect(verdict.shouldQuarantine, isFalse);
      expect(verdict.attempts, 1);
      expect(verdict.stuckFor, Duration.zero);
      expect(ledger.records, hasLength(1));
      expect(ledger.recordFor('debts#d-1#patch')!.attempts, 1);
    });

    test('llegar a 20 fallos tras 24 h sí cuarentena (ambas compuertas)',
        () async {
      seedHistory(
        target: operation(),
        attempts: 19,
        age: const Duration(hours: 24),
      );

      final verdict = await watchdog.registerFailure(
        operation: operation(),
        error: unknownRejection,
      );

      expect(verdict.shouldQuarantine, isTrue);
      expect(verdict.attempts, 20);
      expect(verdict.stuckFor, greaterThanOrEqualTo(const Duration(hours: 24)));
    });

    test('19 fallos NO cuarentenan por más viejo que sea el primero', () async {
      // 30 días atascado, pero un intento por debajo del umbral: la compuerta
      // de intentos sola tiene que bastar para no disparar.
      seedHistory(
        target: operation(),
        attempts: 18,
        age: const Duration(days: 30),
      );

      final verdict = await watchdog.registerFailure(
        operation: operation(),
        error: unknownRejection,
      );

      expect(verdict.attempts, 19);
      expect(verdict.shouldQuarantine, isFalse);
    });

    test(
        '20 fallos en 23 h 59 min NO cuarentenan (falta la compuerta de '
        'tiempo)', () async {
      seedHistory(
        target: operation(),
        attempts: 19,
        age: const Duration(hours: 23, minutes: 59),
      );

      final verdict = await watchdog.registerFailure(
        operation: operation(),
        error: unknownRejection,
      );

      expect(verdict.attempts, 20);
      expect(verdict.stuckFor, lessThan(const Duration(hours: 24)));
      expect(verdict.shouldQuarantine, isFalse);
    });

    test('OUTAGE: 500 rechazos en una hora no cuarentenan nada', () async {
      // Una caída del backend produce muchísimos rechazos en poco tiempo. Es
      // el falso positivo que la compuerta de tiempo existe para evitar.
      seedHistory(
        target: operation(),
        attempts: 499,
        age: const Duration(hours: 1),
      );

      final verdict = await watchdog.registerFailure(
        operation: operation(),
        error: const PostgrestException(message: 'down', code: '503'),
      );

      expect(verdict.attempts, 500);
      expect(verdict.shouldQuarantine, isFalse);
    });

    test('un único fallo hace 30 días tampoco cuarentena', () async {
      // La app pudo estar cerrada meses entre dos intentos: el tiempo solo,
      // sin insistencia real del backend, no es evidencia de atasco.
      seedHistory(
        target: operation(),
        attempts: 1,
        age: const Duration(days: 30),
      );

      final verdict = await watchdog.registerFailure(
        operation: operation(),
        error: unknownRejection,
      );

      expect(verdict.attempts, 2);
      expect(verdict.stuckFor, greaterThan(const Duration(days: 29)));
      expect(verdict.shouldQuarantine, isFalse);
    });

    test('pasado el umbral, cada fallo posterior sigue cuarentenando',
        () async {
      seedHistory(
        target: operation(),
        attempts: 40,
        age: const Duration(days: 3),
      );

      final verdict = await watchdog.registerFailure(
        operation: operation(),
        error: unknownRejection,
      );

      expect(verdict.attempts, 41);
      expect(verdict.shouldQuarantine, isTrue);
    });

    test('los umbrales publicados son los que se documentaron', () {
      // Bajarlos convierte una caída del backend en cuarentena; subirlos
      // devuelve la app al escenario de tres días bloqueada.
      expect(SyncRetryWatchdog.maxAttempts, 20);
      expect(SyncRetryWatchdog.minStuckDuration, const Duration(hours: 24));
    });

    test('describe() resume intentos y horas para el log y el crash report',
        () async {
      seedHistory(
        target: operation(),
        attempts: 19,
        age: const Duration(hours: 30),
      );

      final verdict = await watchdog.registerFailure(
        operation: operation(),
        error: unknownRejection,
      );

      expect(verdict.describe(), '20 rejections over 30h');
    });

    test('el primer fallo conserva firstFailureAt: el reloj no se reinicia',
        () async {
      final seeded = seedHistory(
        target: operation(),
        attempts: 5,
        age: const Duration(hours: 40),
      );

      await watchdog.registerFailure(
        operation: operation(),
        error: unknownRejection,
      );

      final stored = ledger.recordFor(seeded.key)!;
      expect(stored.firstFailureAt, seeded.firstFailureAt);
      expect(stored.lastFailureAt.isAfter(seeded.lastFailureAt), isTrue);
      expect(stored.lastErrorCode, 'WEIRD-CODE');
    });
  });

  group('los fallos de conectividad NO cuentan', () {
    // Cada uno de los tipos que `SyncErrorClassifier.isConnectivityFailure`
    // reconoce. En todos, el backend nunca juzgó la escritura: contarlos
    // convertiría "estar sin red" en pérdida percibida de datos.
    final connectivityFailures = <String, Object>{
      'SocketException (sin ruta / DNS caído)':
          const SocketException('network is unreachable'),
      'TlsException (handshake fallido)': const TlsException('handshake'),
      'HttpException (conexión cortada antes de la respuesta)':
          const HttpException('connection closed before full header'),
      'http.ClientException (fallo de transporte de postgrest-dart)':
          http.ClientException('connection closed'),
      'TimeoutException (la petición nunca obtuvo respuesta)':
          TimeoutException('no response', const Duration(seconds: 30)),
      'AuthException (sin sesión / token no renovable)':
          const AuthException('refresh token expired'),
      'PostgrestException PGRST301 (JWT vencido)':
          const PostgrestException(message: 'jwt expired', code: 'PGRST301'),
      'PostgrestException 408 (timeout del gateway)':
          const PostgrestException(message: 'timeout', code: '408'),
    };

    connectivityFailures.forEach((description, error) {
      test('$description no cuenta ni cuarentena, aun al borde del umbral',
          () async {
        // Sembrado a un fallo de la cuarentena: si este contara, dispararía.
        final seeded = seedHistory(
          target: operation(),
          attempts: 19,
          age: const Duration(days: 5),
        );

        final verdict = await watchdog.registerFailure(
          operation: operation(),
          error: error,
        );

        expect(verdict.shouldQuarantine, isFalse);
        expect(verdict.attempts, 0);
        expect(verdict.stuckFor, Duration.zero);
        // Y el ledger queda intacto: ni se incrementa ni se toca la fecha.
        final stored = ledger.recordFor(seeded.key)!;
        expect(stored.attempts, 19);
        expect(stored.lastFailureAt, seeded.lastFailureAt);
      });
    });

    test('SIN RED: 200 fallos seguidos no crean ni una entrada en el ledger',
        () async {
      for (var i = 0; i < 200; i++) {
        final verdict = await watchdog.registerFailure(
          operation: operation(),
          error: const SocketException('offline'),
        );
        expect(verdict.shouldQuarantine, isFalse);
      }

      // Un usuario sin red puede acumular reintentos indefinidamente sin
      // perder nada a cuarentena.
      expect(ledger.records, isEmpty);
    });

    test(
        'la racha sin red no borra lo ya contado: al volver el rechazo real, '
        'la cuenta sigue donde estaba', () async {
      seedHistory(
        target: operation(),
        attempts: 19,
        age: const Duration(hours: 25),
      );

      await watchdog.registerFailure(
        operation: operation(),
        error: const SocketException('offline'),
      );
      final verdict = await watchdog.registerFailure(
        operation: operation(),
        error: unknownRejection,
      );

      expect(verdict.attempts, 20);
      expect(verdict.shouldQuarantine, isTrue);
    });
  });

  group('isConnectivityFailure es allow-list: lo no listado SÍ cuenta', () {
    // La regla inversa ("contar solo lo que reconocemos como respuesta del
    // servidor") dejaría vivo justo el agujero original: un fallo
    // determinista del cliente no es un problema de red y bloquearía la cola
    // FIFO para siempre otra vez.
    final countedFailures = <String, Object>{
      'una fila que no serializa (JsonUnsupportedObjectError)':
          JsonUnsupportedObjectError(Object()),
      'un bug del uploader (StateError)': StateError('unexpected null column'),
      'un argumento inválido (ArgumentError)': ArgumentError('bad payload'),
      'una respuesta ilegible (FormatException)':
          const FormatException('not json'),
      'un código de backend desconocido': unknownRejection,
      'un 503 del backend (respondió, aunque mal)':
          const PostgrestException(message: 'down', code: '503'),
      'un 429 (rate limit)':
          const PostgrestException(message: 'slow down', code: '429'),
    };

    countedFailures.forEach((description, error) {
      test('$description cuenta y termina en cuarentena tras ambas compuertas',
          () async {
        seedHistory(
          target: operation(),
          attempts: 19,
          age: const Duration(hours: 25),
        );

        final verdict = await watchdog.registerFailure(
          operation: operation(),
          error: error,
        );

        expect(verdict.attempts, 20);
        expect(verdict.shouldQuarantine, isTrue);
      });
    });

    test('un fallo determinista del cliente se acumula fallo a fallo',
        () async {
      final error = JsonUnsupportedObjectError(Object());

      final first = await watchdog.registerFailure(
        operation: operation(),
        error: error,
      );
      final second = await watchdog.registerFailure(
        operation: operation(),
        error: error,
      );
      final third = await watchdog.registerFailure(
        operation: operation(),
        error: error,
      );

      expect([first.attempts, second.attempts, third.attempts], [1, 2, 3]);
    });
  });

  group('identidad de la operación', () {
    test('la clave es tabla#fila#tipo', () {
      expect(
        SyncRetryRecord.keyOf(operation(type: SyncOperationType.delete)),
        'debts#d-1#delete',
      );
    });

    test('dos escrituras distintas de la misma fila se cuentan aparte',
        () async {
      seedHistory(
        target: operation(type: SyncOperationType.patch),
        attempts: 19,
        age: const Duration(hours: 25),
      );

      final other = await watchdog.registerFailure(
        operation: operation(type: SyncOperationType.delete),
        error: unknownRejection,
      );

      expect(other.attempts, 1);
      expect(other.shouldQuarantine, isFalse);
      expect(ledger.records, hasLength(2));
    });

    test('la misma fila en otra tabla se cuenta aparte', () async {
      seedHistory(
        target: operation(),
        attempts: 19,
        age: const Duration(hours: 25),
      );

      final other = await watchdog.registerFailure(
        operation: operation(tableName: 'goals'),
        error: unknownRejection,
      );

      expect(other.attempts, 1);
      expect(ledger.recordFor('goals#d-1#patch'), isNotNull);
    });
  });

  group('forget: una subida exitosa borra el historial', () {
    test('borra el registro de esa operación', () async {
      seedHistory(
        target: operation(),
        attempts: 19,
        age: const Duration(hours: 25),
      );

      await watchdog.forget(operation());

      expect(ledger.records, isEmpty);
    });

    test(
        'un fallo aislado no se acumula para siempre: tras el éxito, el '
        'siguiente fallo vuelve a contar desde 1', () async {
      await watchdog.registerFailure(
        operation: operation(),
        error: unknownRejection,
      );

      await watchdog.forget(operation());
      final verdict = await watchdog.registerFailure(
        operation: operation(),
        error: unknownRejection,
      );

      expect(verdict.attempts, 1);
      expect(verdict.stuckFor, Duration.zero);
    });

    test('no toca el historial de otras operaciones', () async {
      seedHistory(target: operation(), attempts: 3, age: Duration.zero);
      seedHistory(
        target: operation(rowId: 'd-2'),
        attempts: 7,
        age: Duration.zero,
      );

      await watchdog.forget(operation());

      expect(ledger.records.keys, ['debts#d-2#patch']);
    });

    test('olvidar algo que nunca falló no es un error', () async {
      await expectLater(watchdog.forget(operation()), completes);
    });
  });

  group('falla abierto: nunca lanza y nunca cuarentena por un error de I/O',
      () {
    test('si el ledger no se puede leer, el veredicto es seguir reintentando',
        () async {
      ledger.readError = const FileSystemException('disk unreadable');

      final verdict = await watchdog.registerFailure(
        operation: operation(),
        error: unknownRejection,
      );

      // Cuarentenar por un fallo del disco sería sacar de la cola una
      // escritura que quizá iba a subir bien.
      expect(verdict.shouldQuarantine, isFalse);
      expect(verdict.attempts, 0);
    });

    test('si el ledger no se puede escribir, tampoco cuarentena', () async {
      seedHistory(
        target: operation(),
        attempts: 19,
        age: const Duration(hours: 25),
      );
      ledger.upsertError = const FileSystemException('disk full');

      final verdict = await watchdog.registerFailure(
        operation: operation(),
        error: unknownRejection,
      );

      expect(verdict.shouldQuarantine, isFalse);
    });

    test('si la poda falla, el veredicto ya ganado se conserva', () async {
      // La poda tiene su propio guard: es mantenimiento, no parte del
      // veredicto. Un disco lleno no puede enmascarar un atasco real —
      // descartar en silencio una cuarentena ya calculada es exactamente
      // cómo un bloqueo permanece invisible (decisión #22).
      // Fallar abierto sigue aplicando a lo que no se pudo *calcular*: ver
      // los tests de readAll/upsert rotos más arriba.
      for (var i = 0; i < 201; i++) {
        final at = DateTime.now();
        ledger.seed(
          SyncRetryRecord(
            key: 'noise#$i#put',
            attempts: 1,
            firstFailureAt: at,
            lastFailureAt: at,
          ),
        );
      }
      seedHistory(
        target: operation(),
        attempts: 19,
        age: const Duration(hours: 25),
      );
      ledger.removeError = const FileSystemException('cannot rewrite');

      final verdict = await watchdog.registerFailure(
        operation: operation(),
        error: unknownRejection,
      );

      expect(verdict.shouldQuarantine, isTrue);
      expect(verdict.attempts, 20);
    });

    test('forget nunca propaga el error del almacenamiento', () async {
      ledger.removeError = const FileSystemException('cannot rewrite');

      await expectLater(watchdog.forget(operation()), completes);
    });
  });

  group('el ledger está acotado a 200 entradas', () {
    /// Siembra [count] registros con `lastFailureAt` creciente: `stale#0` es
    /// el más viejo.
    void seedNoise(int count) {
      final base = DateTime.now().subtract(const Duration(days: 10));
      for (var i = 0; i < count; i++) {
        ledger.seed(
          SyncRetryRecord(
            key: 'stale#$i#put',
            attempts: 1,
            firstFailureAt: base,
            lastFailureAt: base.add(Duration(minutes: i)),
          ),
        );
      }
    }

    test('con 200 entradas exactas no se evicta nada', () async {
      seedNoise(199);

      await watchdog.registerFailure(
        operation: operation(),
        error: unknownRejection,
      );

      expect(ledger.records, hasLength(200));
      expect(ledger.recordFor('stale#0#put'), isNotNull);
    });

    test('la entrada 201 evicta la de lastFailureAt más viejo', () async {
      seedNoise(200);

      await watchdog.registerFailure(
        operation: operation(),
        error: unknownRejection,
      );

      expect(ledger.records, hasLength(200));
      expect(ledger.recordFor('stale#0#put'), isNull);
      expect(ledger.recordFor('stale#1#put'), isNotNull);
      expect(ledger.recordFor('debts#d-1#patch'), isNotNull);
    });

    test('evicta por lastFailureAt, no por orden de inserción', () async {
      final now = DateTime.now();
      for (var i = 0; i < 200; i++) {
        // El insertado de último es el más viejo por fecha.
        final age = Duration(minutes: i + 1);
        ledger.seed(
          SyncRetryRecord(
            key: 'stale#$i#put',
            attempts: 1,
            firstFailureAt: now.subtract(age),
            lastFailureAt: now.subtract(age),
          ),
        );
      }

      await watchdog.registerFailure(
        operation: operation(),
        error: unknownRejection,
      );

      expect(ledger.recordFor('stale#199#put'), isNull);
      expect(ledger.recordFor('stale#0#put'), isNotNull);
    });

    test('lo que está cerca de cuarentenar sobrevive la poda', () async {
      seedNoise(200);
      // Un candidato real: falló hace un instante, 19 veces, desde hace días.
      seedHistory(
        target: operation(),
        attempts: 19,
        age: const Duration(hours: 25),
      );

      // Otra operación cualquiera empuja el ledger por encima del límite.
      await watchdog.registerFailure(
        operation: operation(rowId: 'd-9'),
        error: unknownRejection,
      );
      final verdict = await watchdog.registerFailure(
        operation: operation(),
        error: unknownRejection,
      );

      expect(verdict.attempts, 20);
      expect(verdict.shouldQuarantine, isTrue);
    });

    test('excederse por mucho evicta todo lo necesario de una sola vez',
        () async {
      seedNoise(250);

      await watchdog.registerFailure(
        operation: operation(),
        error: unknownRejection,
      );

      expect(ledger.records, hasLength(200));
      expect(ledger.recordFor('debts#d-1#patch'), isNotNull);
    });
  });
}
