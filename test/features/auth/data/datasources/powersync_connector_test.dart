import 'dart:convert';
import 'dart:io';

import 'package:billetudo/core/config/env.dart';
import 'package:billetudo/core/crash/crash_reporter.dart';
import 'package:billetudo/core/database/powersync_schema.dart';
import 'package:billetudo/core/sync/data/datasources/sync_operation_uploader.dart';
import 'package:billetudo/core/sync/data/datasources/sync_retry_watchdog.dart';
import 'package:billetudo/core/sync/data/models/sync_retry_record.dart';
import 'package:billetudo/core/sync/domain/entities/sync_failure_kind.dart';
import 'package:billetudo/core/sync/domain/entities/sync_log_entry.dart';
import 'package:billetudo/core/sync/domain/entities/sync_operation.dart';
import 'package:billetudo/core/sync/domain/repositories/sync_log_repository.dart';
import 'package:billetudo/core/sync/domain/repositories/sync_quarantine_repository.dart';
import 'package:billetudo/features/auth/data/datasources/powersync_connector.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:mocktail/mocktail.dart';
import 'package:powersync/powersync.dart' as ps;
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../support/fake_sync_retry_ledger_store.dart';

class MockCrashReporter extends Mock implements CrashReporter {}

class MockSyncOperationUploader extends Mock implements SyncOperationUploader {}

class MockSyncQuarantineRepository extends Mock
    implements SyncQuarantineRepository {}

class MockSyncLogRepository extends Mock implements SyncLogRepository {}

class FakeSyncOperation extends Fake implements SyncOperation {}

/// Stand-in for the timeout an HTTP client throws: anything that is not a
/// `PostgrestException` must be classified as transient.
class FakeTimeoutException implements Exception {
  const FakeTimeoutException();

  @override
  String toString() => 'FakeTimeoutException: request timed out';
}

/// `PowerSyncDatabase` is an `abstract base class` with a private constructor,
/// so it can neither be mocked nor extended from outside its library. These
/// tests therefore drive the connector with a **real** PowerSync database on a
/// temp file (never connected to the sync service): local writes fill the real
/// CRUD queue, which is exactly what `uploadData` consumes.
///
/// The upload transport is mocked at [SyncOperationUploader]: these tests are
/// about *how the connector reacts to a failed operation*, not about how the
/// operation is serialized — that belongs to
/// `test/core/sync/data/datasources/supabase_operation_uploader_test.dart`.
///
/// The scenario that gives this file its reason to exist: Postgres was missing
/// `debts.closed_at`, PostgREST answered `PGRST204`, the old connector rethrew
/// it as transient, PowerSync retried the same transaction forever and — the
/// queue being FIFO — blocked every write of every table for three days. 89
/// unsynced changes were lost. Every assertion below about the queue advancing
/// is guarding exactly that.
void main() {
  setUpAll(() {
    registerFallbackValue(StackTrace.empty);
    registerFallbackValue(FakeSyncOperation());
    registerFallbackValue(SyncFailureKind.transient);
    registerFallbackValue(SyncLogEvent.uploadStarted);
    registerFallbackValue(SyncLogLevel.info);
  });

  late MockSyncOperationUploader uploader;
  late MockSyncQuarantineRepository quarantine;
  late MockSyncLogRepository log;
  late MockCrashReporter crash;
  late FakeSyncRetryLedgerStore ledger;

  setUp(() {
    ledger = FakeSyncRetryLedgerStore();
    uploader = MockSyncOperationUploader();
    quarantine = MockSyncQuarantineRepository();
    log = MockSyncLogRepository();
    crash = MockCrashReporter();

    when(() => uploader.upload(any())).thenAnswer((_) async {});
    when(
      () => quarantine.record(
        operation: any(named: 'operation'),
        kind: any(named: 'kind'),
        errorMessage: any(named: 'errorMessage'),
        errorCode: any(named: 'errorCode'),
      ),
    ).thenAnswer((_) async {});
    when(
      () => log.record(
        event: any(named: 'event'),
        message: any(named: 'message'),
        level: any(named: 'level'),
        code: any(named: 'code'),
        tableName: any(named: 'tableName'),
      ),
    ).thenAnswer((_) async {});
    when(
      () => crash.recordError(
        any(),
        any(),
        context: any(named: 'context'),
        fatal: any(named: 'fatal'),
      ),
    ).thenAnswer((_) async {});
  });

  Future<ps.PowerSyncDatabase> openDatabase() async {
    final dir = Directory.systemTemp.createTempSync('powersync_connector_test');
    final db = ps.PowerSyncDatabase(
      schema: powerSyncSchema,
      path: '${dir.path}/test.db',
    );
    await db.initialize();
    addTearDown(() async {
      await db.close();
      dir.deleteSync(recursive: true);
    });
    return db;
  }

  /// Enqueues a CRUD entry straight into PowerSync's queue, for shapes a normal
  /// local write cannot produce (a PUT with no data).
  Future<void> enqueueRawOp(
    ps.PowerSyncDatabase db, {
    required String op,
    required String table,
    required String id,
    Map<String, dynamic>? data,
  }) =>
      db.execute(
        'INSERT INTO ps_crud(tx_id, data) VALUES(?, ?)',
        [
          99,
          jsonEncode({'op': op, 'type': table, 'id': id, 'data': data}),
        ],
      );

  Future<int> queuedOps(ps.PowerSyncDatabase db) async {
    final rows = await db.getAll('SELECT COUNT(*) AS c FROM ps_crud');
    return rows.single['c'] as int;
  }

  /// A Supabase session that never hits the network: `setInitialSession` only
  /// deserializes it, and the far-future expiry avoids any refresh call.
  String sessionJson(String userId) => jsonEncode({
        'access_token': 'jwt-for-$userId',
        'token_type': 'bearer',
        'expires_in': 3600,
        'expires_at': DateTime.now()
                .add(const Duration(hours: 1))
                .millisecondsSinceEpoch ~/
            1000,
        'refresh_token': 'refresh-token',
        'user': {
          'id': userId,
          'app_metadata': <String, dynamic>{},
          'user_metadata': <String, dynamic>{},
          'aud': 'authenticated',
          'created_at': '2026-01-01T00:00:00Z',
        },
      });

  Future<SupabaseClient> buildSupabase({String? signedInUserId}) async {
    final client = SupabaseClient(
      'https://example.supabase.co',
      'anon-key',
      httpClient: MockClient(
        (request) async => http.Response('', 201, request: request),
      ),
    );
    addTearDown(client.dispose);
    if (signedInUserId != null) {
      await client.auth.setInitialSession(sessionJson(signedInUserId));
    }
    return client;
  }

  Future<PowerSyncConnector> buildConnector({String? signedInUserId}) async {
    final supabase = await buildSupabase(signedInUserId: signedInUserId);
    return PowerSyncConnector(
      supabase,
      uploader,
      quarantine,
      log,
      crash,
      SyncRetryWatchdog(ledger),
    );
  }

  PostgrestException postgrestError(String code) =>
      PostgrestException(message: 'boom', code: code);

  /// Fails the upload of [tableName] with [error]; everything else succeeds.
  void failUploadsOf(String tableName, Object error) {
    when(() => uploader.upload(any())).thenAnswer((invocation) async {
      final operation = invocation.positionalArguments.single as SyncOperation;
      if (operation.tableName == tableName) {
        // Reproducir el fallo REAL del backend es el punto de estos tests: el
        // clasificador debe tratar como transitorio cualquier cosa que no sea
        // un PostgrestException, incluidos objetos que no son Error.
        // ignore: only_throw_errors
        throw error;
      }
    });
  }

  List<SyncOperation> uploadedOperations() =>
      verify(() => uploader.upload(captureAny()))
          .captured
          .cast<SyncOperation>();

  group('fetchCredentials', () {
    test('devuelve null cuando no hay sesión (local-first, no es error)',
        () async {
      final connector = await buildConnector();

      expect(await connector.fetchCredentials(), isNull);
      verify(
        () => log.record(
          event: SyncLogEvent.connection,
          message: any(named: 'message'),
        ),
      ).called(1);
    });

    test('no repite la línea de log de "sin sesión" en cada refresco',
        () async {
      final connector = await buildConnector();

      await connector.fetchCredentials();
      await connector.fetchCredentials();
      await connector.fetchCredentials();

      verify(
        () => log.record(
          event: SyncLogEvent.connection,
          message: any(named: 'message'),
        ),
      ).called(1);
    });

    test(
      'devuelve endpoint, token y userId de la sesión activa',
      () async {
        final connector = await buildConnector(signedInUserId: 'user-1');

        final credentials = await connector.fetchCredentials();

        expect(credentials, isNotNull);
        expect(credentials!.endpoint, Env.powerSyncUrl);
        expect(credentials.token, 'jwt-for-user-1');
        expect(credentials.userId, 'user-1');
      },
      skip: Env.powerSyncUrl.isEmpty
          ? 'Requiere --dart-define=POWERSYNC_URL=https://... : '
              'PowerSyncCredentials valida el endpoint y lo rechaza vacío.'
          : null,
    );

    test(
      'sin POWERSYNC_URL definido, el endpoint vacío es rechazado',
      () async {
        final connector = await buildConnector(signedInUserId: 'user-1');

        await expectLater(
          connector.fetchCredentials(),
          throwsA(isA<ArgumentError>()),
        );
      },
      skip: Env.powerSyncUrl.isEmpty
          ? null
          : 'Solo aplica cuando POWERSYNC_URL no está definido.',
    );
  });

  group('uploadData', () {
    test('retorna sin subir nada cuando la cola está vacía', () async {
      final db = await openDatabase();
      final connector = await buildConnector(signedInUserId: 'user-1');

      await connector.uploadData(db);

      verifyNever(() => uploader.upload(any()));
      verifyZeroInteractions(crash);
      verifyNever(
        () => log.record(
          event: SyncLogEvent.uploadStarted,
          message: any(named: 'message'),
        ),
      );
    });

    test('traduce la entrada de PowerSync a SyncOperation y vacía la cola',
        () async {
      final db = await openDatabase();
      await db.execute(
        'INSERT INTO transactions(id, amount_minor, type, updated_at) '
        "VALUES('tx-1', 1234, 'expense', 1700000000000)",
      );
      final connector = await buildConnector(signedInUserId: 'user-1');

      await connector.uploadData(db);

      final operation = uploadedOperations().single;
      expect(operation.tableName, 'transactions');
      expect(operation.rowId, 'tx-1');
      expect(operation.type, SyncOperationType.put);
      // Dinero: entero en unidades menores, jamás double.
      expect(operation.payload!['amount_minor'], 1234);
      expect(operation.payload!['amount_minor'], isA<int>());
      expect(operation.payload!['updated_at'], 1700000000000);
      expect(await queuedOps(db), 0);
      verifyZeroInteractions(crash);
    });

    test('traduce un patch y un delete a su SyncOperationType', () async {
      final db = await openDatabase();
      await db.execute(
        "INSERT INTO categories(id, name) VALUES('c-1', 'Comida')",
      );
      final connector = await buildConnector(signedInUserId: 'user-1');
      await connector.uploadData(db); // consume el PUT inicial
      await db.execute("UPDATE categories SET name='Mercado' WHERE id='c-1'");
      await connector.uploadData(db);
      await db.execute("DELETE FROM categories WHERE id = 'c-1'");

      await connector.uploadData(db);

      final operations = uploadedOperations();
      expect(operations.map((each) => each.type), [
        SyncOperationType.put,
        SyncOperationType.patch,
        SyncOperationType.delete,
      ]);
      expect(operations[1].payload, {'name': 'Mercado'});
      expect(operations[2].rowId, 'c-1');
      expect(await queuedOps(db), 0);
    });

    test(
        'REGRESIÓN (incidente BILLETUDO-2): PGRST204 NO se relanza, va a '
        'cuarentena y la transacción se completa — la cola AVANZA', () async {
      failUploadsOf('debts', postgrestError('PGRST204'));
      final db = await openDatabase();
      await db.execute("INSERT INTO debts(id) VALUES('d-1')");
      final connector = await buildConnector(signedInUserId: 'user-1');

      // 1) No se relanza: PowerSync no reintenta la misma transacción.
      await connector.uploadData(db);

      // 2) La cola quedó vacía: la op dejó de bloquear a todas las tablas.
      expect(await queuedOps(db), 0);

      // 3) Y la escritura no se perdió: está en cuarentena, no descartada.
      final captured = verify(
        () => quarantine.record(
          operation: captureAny(named: 'operation'),
          kind: captureAny(named: 'kind'),
          errorMessage: captureAny(named: 'errorMessage'),
          errorCode: captureAny(named: 'errorCode'),
        ),
      ).captured;
      expect((captured[0] as SyncOperation).tableName, 'debts');
      expect((captured[0] as SyncOperation).rowId, 'd-1');
      expect(captured[1], SyncFailureKind.brokenSchema);
      expect(captured[2], contains('PGRST204'));
      expect(captured[3], 'PGRST204');
    });

    for (final code in ['PGRST205', '42703', '42P01']) {
      test('el esquema roto $code va a cuarentena sin bloquear la cola',
          () async {
        failUploadsOf('debts', postgrestError(code));
        final db = await openDatabase();
        await db.execute("INSERT INTO debts(id) VALUES('d-1')");
        final connector = await buildConnector(signedInUserId: 'user-1');

        await connector.uploadData(db);

        expect(await queuedOps(db), 0);
        verify(
          () => quarantine.record(
            operation: any(named: 'operation'),
            kind: SyncFailureKind.brokenSchema,
            errorMessage: any(named: 'errorMessage'),
            errorCode: code,
          ),
        ).called(1);
      });
    }

    for (final code in ['22007', '23503', '42501']) {
      test(
          'el rechazo de dato/permiso $code va a cuarentena (no se descarta '
          'en silencio)', () async {
        failUploadsOf('transactions', postgrestError(code));
        final db = await openDatabase();
        await db.execute(
          "INSERT INTO transactions(id, amount_minor) VALUES('tx-1', 1234)",
        );
        final connector = await buildConnector(signedInUserId: 'user-1');

        await connector.uploadData(db);

        expect(await queuedOps(db), 0);
        verify(
          () => quarantine.record(
            operation: any(named: 'operation'),
            kind: SyncFailureKind.invalidData,
            errorMessage: any(named: 'errorMessage'),
            errorCode: code,
          ),
        ).called(1);
      });
    }

    test(
        'AISLAMIENTO: en un batch de 3 ops, la que falla permanentemente no '
        'impide que las otras 2 suban', () async {
      failUploadsOf('debts', postgrestError('PGRST204'));
      final db = await openDatabase();
      await db.writeTransaction((tx) async {
        await tx.execute(
          "INSERT INTO transactions(id, amount_minor) VALUES('tx-1', 1234)",
        );
        await tx.execute("INSERT INTO debts(id) VALUES('d-1')");
        await tx.execute("INSERT INTO budgets(id) VALUES('b-1')");
      });
      final connector = await buildConnector(signedInUserId: 'user-1');

      await connector.uploadData(db);

      // Se intentaron las tres, incluida la que va DESPUÉS de la que falla.
      expect(
        uploadedOperations().map((each) => each.tableName),
        containsAll(<String>['transactions', 'debts', 'budgets']),
      );
      // Y solo la rechazada fue a cuarentena.
      verify(
        () => quarantine.record(
          operation: any(named: 'operation'),
          kind: any(named: 'kind'),
          errorMessage: any(named: 'errorMessage'),
          errorCode: any(named: 'errorCode'),
        ),
      ).called(1);
      expect(await queuedOps(db), 0);
    });

    final transientErrors = <String, Object>{
      'SocketException (sin red)':
          const SocketException('network is unreachable'),
      'timeout que no es PostgrestException': const FakeTimeoutException(),
      'error inesperado del cliente': StateError('unexpected'),
      '5xx del backend': const PostgrestException(message: 'boom', code: '503'),
      'PGRST301 (JWT vencido)':
          const PostgrestException(message: 'jwt expired', code: 'PGRST301'),
      'PostgrestException sin código':
          const PostgrestException(message: 'boom'),
    };
    transientErrors.forEach((description, error) {
      test(
          'el fallo transitorio por $description se relanza y la transacción '
          'NO se completa', () async {
        failUploadsOf('transactions', error);
        final db = await openDatabase();
        await db.execute(
          "INSERT INTO transactions(id, amount_minor) VALUES('tx-1', 1234)",
        );
        final connector = await buildConnector(signedInUserId: 'user-1');

        await expectLater(connector.uploadData(db), throwsA(same(error)));

        // La op sigue en la cola: PowerSync reintentará el batch entero.
        expect(await queuedOps(db), 1);
        verifyNever(
          () => quarantine.record(
            operation: any(named: 'operation'),
            kind: any(named: 'kind'),
            errorMessage: any(named: 'errorMessage'),
            errorCode: any(named: 'errorCode'),
          ),
        );
        verify(
          () => log.record(
            event: SyncLogEvent.uploadRetry,
            message: any(named: 'message'),
            level: SyncLogLevel.warning,
            code: any(named: 'code'),
            tableName: 'transactions',
          ),
        ).called(1);
      });
    });

    test('un fallo transitorio aborta las ops posteriores del mismo batch',
        () async {
      failUploadsOf('transactions', const SocketException('offline'));
      final db = await openDatabase();
      await db.writeTransaction((tx) async {
        await tx.execute(
          "INSERT INTO transactions(id, amount_minor) VALUES('tx-1', 1234)",
        );
        await tx.execute("INSERT INTO budgets(id) VALUES('b-1')");
      });
      final connector = await buildConnector(signedInUserId: 'user-1');

      await expectLater(
        connector.uploadData(db),
        throwsA(isA<SocketException>()),
      );

      expect(
        uploadedOperations().map((each) => each.tableName),
        <String>['transactions'],
      );
      expect(await queuedOps(db), 2);
    });

    test('toda op en cuarentena se reporta al CrashReporter', () async {
      failUploadsOf('debts', postgrestError('PGRST204'));
      final db = await openDatabase();
      await db.execute("INSERT INTO debts(id) VALUES('d-1')");
      final connector = await buildConnector(signedInUserId: 'user-1');

      await connector.uploadData(db);

      final captured = verify(
        () => crash.recordError(
          captureAny(),
          captureAny(),
          context: captureAny(named: 'context'),
          fatal: captureAny(named: 'fatal'),
        ),
      ).captured;
      expect(captured[0], isA<PostgrestException>());
      expect((captured[0] as PostgrestException).code, 'PGRST204');
      expect(captured[1], isA<StackTrace>());
      expect(
        captured.whereType<String>().single,
        allOf(
          contains('quarantined'),
          contains('PGRST204'),
          contains('debts'),
        ),
      );
      // Un esquema roto es un bug de despliegue que afecta a toda la tabla:
      // se reporta como fatal para que sea accionable.
      expect(captured.whereType<bool>().single, isTrue);
    });

    test('un rechazo de dato inválido se reporta pero NO como fatal', () async {
      failUploadsOf('transactions', postgrestError('23503'));
      final db = await openDatabase();
      await db.execute(
        "INSERT INTO transactions(id, amount_minor) VALUES('tx-1', 1234)",
      );
      final connector = await buildConnector(signedInUserId: 'user-1');

      await connector.uploadData(db);

      final captured = verify(
        () => crash.recordError(
          any(),
          any(),
          context: any(named: 'context'),
          fatal: captureAny(named: 'fatal'),
        ),
      ).captured;
      expect(captured.single, isFalse);
    });

    test('un fallo transitorio también se reporta al CrashReporter', () async {
      failUploadsOf('transactions', const SocketException('offline'));
      final db = await openDatabase();
      await db.execute(
        "INSERT INTO transactions(id, amount_minor) VALUES('tx-1', 1234)",
      );
      final connector = await buildConnector(signedInUserId: 'user-1');

      await expectLater(
        connector.uploadData(db),
        throwsA(isA<SocketException>()),
      );

      final captured = verify(
        () => crash.recordError(
          any(),
          any(),
          context: captureAny(named: 'context'),
          fatal: any(named: 'fatal'),
        ),
      ).captured;
      expect(
        captured.single,
        allOf(
          isA<String>(),
          contains('retrying'),
          isNot(contains('quarantined')),
        ),
      );
    });

    test('el log registra inicio y cierre con el conteo de cuarentenadas',
        () async {
      failUploadsOf('debts', postgrestError('PGRST204'));
      final db = await openDatabase();
      await db.writeTransaction((tx) async {
        await tx.execute("INSERT INTO debts(id) VALUES('d-1')");
        await tx.execute("INSERT INTO budgets(id) VALUES('b-1')");
      });
      final connector = await buildConnector(signedInUserId: 'user-1');

      await connector.uploadData(db);

      final started = verify(
        () => log.record(
          event: SyncLogEvent.uploadStarted,
          message: captureAny(named: 'message'),
        ),
      ).captured;
      expect(started.single, contains('2 operation'));

      final finished = verify(
        () => log.record(
          event: SyncLogEvent.uploadFinished,
          message: captureAny(named: 'message'),
          level: SyncLogLevel.warning,
        ),
      ).captured;
      expect(
        finished.single,
        allOf(contains('1 uploaded'), contains('1 quarantined')),
      );
    });

    test('sin cuarentenadas el cierre se registra en nivel info', () async {
      final db = await openDatabase();
      await db.execute("INSERT INTO budgets(id) VALUES('b-1')");
      final connector = await buildConnector(signedInUserId: 'user-1');

      await connector.uploadData(db);

      verify(
        () => log.record(
          event: SyncLogEvent.uploadFinished,
          message: any(named: 'message'),
          level: SyncLogLevel.info,
        ),
      ).called(1);
    });

    /// Deja el ledger del watchdog a un fallo de la cuarentena para
    /// `<tableName>#<rowId>#put`: [attempts] rechazos contados cuyo primero
    /// ocurrió hace [age].
    void seedRetryHistory({
      String tableName = 'debts',
      String rowId = 'd-1',
      int attempts = 19,
      Duration age = const Duration(hours: 25),
    }) {
      final now = DateTime.now();
      ledger.seed(
        SyncRetryRecord(
          key: '$tableName#$rowId#put',
          attempts: attempts,
          firstFailureAt: now.subtract(age),
          lastFailureAt: now,
          lastErrorCode: 'WEIRD-CODE',
        ),
      );
    }

    test('un put sin opData llega al uploader con payload nulo', () async {
      final db = await openDatabase();
      await enqueueRawOp(
        db,
        op: 'PUT',
        table: 'scheduled_payments',
        id: 'sp-1',
      );
      final connector = await buildConnector(signedInUserId: 'user-1');

      await connector.uploadData(db);

      final operation = uploadedOperations().single;
      expect(operation.rowId, 'sp-1');
      expect(operation.type, SyncOperationType.put);
      expect(operation.payload, isNull);
      expect(await queuedOps(db), 0);
    });

    group('watchdog de reintentos', () {
      test(
          'REGRESIÓN: un código imprevisto que ya agotó las dos compuertas va '
          'a cuarentena como stuck y la cola AVANZA', () async {
        // La forma exacta del incidente, pero con un código que el
        // clasificador NO conoce: sin watchdog esto se relanzaría para
        // siempre y volvería a congelar la cola FIFO.
        seedRetryHistory();
        failUploadsOf('debts', postgrestError('WEIRD-CODE'));
        final db = await openDatabase();
        await db.execute("INSERT INTO debts(id) VALUES('d-1')");
        final connector = await buildConnector(signedInUserId: 'user-1');

        // 1) No se relanza.
        await connector.uploadData(db);

        // 2) La cola avanza: `ps_crud` queda en 0.
        expect(await queuedOps(db), 0);

        // 3) Y la escritura no se pierde: queda en cuarentena como `stuck`.
        final captured = verify(
          () => quarantine.record(
            operation: captureAny(named: 'operation'),
            kind: captureAny(named: 'kind'),
            errorMessage: captureAny(named: 'errorMessage'),
            errorCode: captureAny(named: 'errorCode'),
          ),
        ).captured;
        expect((captured[0] as SyncOperation).tableName, 'debts');
        expect((captured[0] as SyncOperation).rowId, 'd-1');
        expect(captured[1], SyncFailureKind.stuck);
        expect(
          captured[2],
          allOf(
            contains('retry watchdog'),
            contains('20 rejections over 25h'),
            contains('WEIRD-CODE'),
          ),
        );
        expect(captured[3], 'WEIRD-CODE');
      });

      test(
          'registra el evento watchdogQuarantined, distinto del de un '
          'rechazo clasificado', () async {
        seedRetryHistory();
        failUploadsOf('debts', postgrestError('WEIRD-CODE'));
        final db = await openDatabase();
        await db.execute("INSERT INTO debts(id) VALUES('d-1')");
        final connector = await buildConnector(signedInUserId: 'user-1');

        await connector.uploadData(db);

        final captured = verify(
          () => log.record(
            event: SyncLogEvent.watchdogQuarantined,
            message: captureAny(named: 'message'),
            level: SyncLogLevel.error,
            code: 'WEIRD-CODE',
            tableName: 'debts',
          ),
        ).captured;
        expect(captured.single, contains('20 rejections over 25h'));
        verifyNever(
          () => log.record(
            event: SyncLogEvent.quarantined,
            message: any(named: 'message'),
            level: any(named: 'level'),
            code: any(named: 'code'),
            tableName: any(named: 'tableName'),
          ),
        );
      });

      test(
          'se reporta al CrashReporter como fatal y con un contexto que no se '
          'puede confundir con un rechazo clasificado', () async {
        seedRetryHistory();
        failUploadsOf('debts', postgrestError('WEIRD-CODE'));
        final db = await openDatabase();
        await db.execute("INSERT INTO debts(id) VALUES('d-1')");
        final connector = await buildConnector(signedInUserId: 'user-1');

        await connector.uploadData(db);

        final captured = verify(
          () => crash.recordError(
            captureAny(),
            captureAny(),
            context: captureAny(named: 'context'),
            fatal: captureAny(named: 'fatal'),
          ),
        ).captured;
        expect((captured[0] as PostgrestException).code, 'WEIRD-CODE');
        expect(captured[1], isA<StackTrace>());
        expect(
          captured.whereType<String>().single,
          allOf(
            contains('UNCLASSIFIED SYNC FAILURE'),
            contains('retry watchdog'),
            contains('20 rejections over 25h'),
            contains('debts'),
            // El texto del camino clasificado ("PowerSync upload quarantined
            // a brokenSchema rejection"): si apareciera, en Sentry serían el
            // mismo issue y este modo de falla volvería a pasar inadvertido.
            isNot(contains('PowerSync upload quarantined')),
            isNot(contains('is retrying')),
          ),
        );
        // Llegar aquí significa que hay en producción un modo de falla que
        // nadie previó: es la señal que faltó durante tres días.
        expect(captured.whereType<bool>().single, isTrue);
      });

      test('tras cuarentenar, el historial del watchdog se olvida', () async {
        seedRetryHistory();
        failUploadsOf('debts', postgrestError('WEIRD-CODE'));
        final db = await openDatabase();
        await db.execute("INSERT INTO debts(id) VALUES('d-1')");
        final connector = await buildConnector(signedInUserId: 'user-1');

        await connector.uploadData(db);

        expect(ledger.records, isEmpty);
      });

      test(
          'ANTES de las compuertas, el mismo código se relanza y la cola NO '
          'avanza', () async {
        failUploadsOf('transactions', postgrestError('WEIRD-CODE'));
        final db = await openDatabase();
        await db.execute(
          "INSERT INTO transactions(id, amount_minor) VALUES('tx-1', 1234)",
        );
        final connector = await buildConnector(signedInUserId: 'user-1');

        await expectLater(
          connector.uploadData(db),
          throwsA(isA<PostgrestException>()),
        );

        expect(await queuedOps(db), 1);
        expect(ledger.recordFor('transactions#tx-1#put')!.attempts, 1);
        verifyNever(
          () => quarantine.record(
            operation: any(named: 'operation'),
            kind: any(named: 'kind'),
            errorMessage: any(named: 'errorMessage'),
            errorCode: any(named: 'errorCode'),
          ),
        );
      });

      test(
          'SIN RED: con el ledger al borde del umbral, un SocketException no '
          'cuarentena nada ni cuenta', () async {
        // Un usuario sin conexión tiene que poder acumular reintentos
        // indefinidamente sin que se le saque una escritura de la cola.
        seedRetryHistory(tableName: 'transactions', rowId: 'tx-1');
        failUploadsOf('transactions', const SocketException('offline'));
        final db = await openDatabase();
        await db.execute(
          "INSERT INTO transactions(id, amount_minor) VALUES('tx-1', 1234)",
        );
        final connector = await buildConnector(signedInUserId: 'user-1');

        await expectLater(
          connector.uploadData(db),
          throwsA(isA<SocketException>()),
        );

        expect(await queuedOps(db), 1);
        expect(ledger.recordFor('transactions#tx-1#put')!.attempts, 19);
        verifyNever(
          () => quarantine.record(
            operation: any(named: 'operation'),
            kind: any(named: 'kind'),
            errorMessage: any(named: 'errorMessage'),
            errorCode: any(named: 'errorCode'),
          ),
        );
      });

      test('una subida exitosa olvida el historial de esa operación', () async {
        seedRetryHistory(tableName: 'transactions', rowId: 'tx-1');
        final db = await openDatabase();
        await db.execute(
          "INSERT INTO transactions(id, amount_minor) VALUES('tx-1', 1234)",
        );
        final connector = await buildConnector(signedInUserId: 'user-1');

        await connector.uploadData(db);

        expect(ledger.records, isEmpty);
      });

      test('un rechazo clasificado también limpia el ledger', () async {
        seedRetryHistory();
        failUploadsOf('debts', postgrestError('PGRST204'));
        final db = await openDatabase();
        await db.execute("INSERT INTO debts(id) VALUES('d-1')");
        final connector = await buildConnector(signedInUserId: 'user-1');

        await connector.uploadData(db);

        expect(ledger.records, isEmpty);
        verify(
          () => quarantine.record(
            operation: any(named: 'operation'),
            kind: SyncFailureKind.brokenSchema,
            errorMessage: any(named: 'errorMessage'),
            errorCode: 'PGRST204',
          ),
        ).called(1);
      });

      test('la op atascada sale del batch y el resto sube: la cola queda en 0',
          () async {
        seedRetryHistory();
        failUploadsOf('debts', postgrestError('WEIRD-CODE'));
        final db = await openDatabase();
        await db.writeTransaction((tx) async {
          await tx.execute("INSERT INTO debts(id) VALUES('d-1')");
          await tx.execute("INSERT INTO budgets(id) VALUES('b-1')");
          await tx.execute(
            "INSERT INTO transactions(id, amount_minor) VALUES('tx-1', 1234)",
          );
        });
        final connector = await buildConnector(signedInUserId: 'user-1');

        await connector.uploadData(db);

        expect(await queuedOps(db), 0);
        expect(
          uploadedOperations().map((each) => each.tableName),
          containsAll(<String>['debts', 'budgets', 'transactions']),
        );
        verify(
          () => log.record(
            event: SyncLogEvent.uploadFinished,
            message: any(
              named: 'message',
              that: allOf(contains('2 uploaded'), contains('1 quarantined')),
            ),
            level: SyncLogLevel.warning,
          ),
        ).called(1);
      });

      test('si el ledger está roto, se sigue reintentando (falla abierto)',
          () async {
        // Cuarentenar por un error de disco sería sacar de la cola una
        // escritura que quizá iba a subir bien.
        ledger.readError = const FileSystemException('disk unreadable');
        failUploadsOf('debts', postgrestError('WEIRD-CODE'));
        final db = await openDatabase();
        await db.execute("INSERT INTO debts(id) VALUES('d-1')");
        final connector = await buildConnector(signedInUserId: 'user-1');

        await expectLater(
          connector.uploadData(db),
          throwsA(isA<PostgrestException>()),
        );

        expect(await queuedOps(db), 1);
        verifyNever(
          () => quarantine.record(
            operation: any(named: 'operation'),
            kind: any(named: 'kind'),
            errorMessage: any(named: 'errorMessage'),
            errorCode: any(named: 'errorCode'),
          ),
        );
      });
    });
  });
}
