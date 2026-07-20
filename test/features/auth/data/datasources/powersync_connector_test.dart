import 'dart:convert';
import 'dart:io';

import 'package:billetudo/core/config/env.dart';
import 'package:billetudo/core/crash/crash_reporter.dart';
import 'package:billetudo/core/database/powersync_schema.dart';
import 'package:billetudo/features/auth/data/datasources/powersync_connector.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:mocktail/mocktail.dart';
import 'package:powersync/powersync.dart' as ps;
import 'package:supabase_flutter/supabase_flutter.dart';

class MockCrashReporter extends Mock implements CrashReporter {}

/// `PowerSyncDatabase` is an `abstract base class` with a private constructor,
/// so it can neither be mocked nor extended from outside its library. These
/// tests therefore drive the connector with a **real** PowerSync database on a
/// temp file (never connected to the sync service): local writes fill the real
/// CRUD queue, which is exactly what `uploadData` consumes. Supabase, on the
/// other hand, is faked at the HTTP layer (`MockClient`) — the same pattern
/// used in `seed_category_ownership_remote_datasource_test.dart`.
void main() {
  setUpAll(() {
    registerFallbackValue(StackTrace.empty);
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
  /// local write cannot produce (an empty PATCH payload, a PUT with no data).
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

  Future<SupabaseClient> buildSupabase({
    String? signedInUserId,
    http.Response Function(http.Request request)? responder,
  }) async {
    final client = SupabaseClient(
      'https://example.supabase.co',
      'anon-key',
      httpClient: MockClient(
        (request) async =>
            responder?.call(request) ??
            http.Response('', 201, request: request),
      ),
    );
    addTearDown(client.dispose);
    if (signedInUserId != null) {
      await client.auth.setInitialSession(sessionJson(signedInUserId));
    }
    return client;
  }

  MockCrashReporter buildCrashReporter() {
    final crash = MockCrashReporter();
    when(
      () => crash.recordError(
        any(),
        any(),
        context: any(named: 'context'),
        fatal: any(named: 'fatal'),
      ),
    ).thenAnswer((_) async {});
    return crash;
  }

  http.Response postgrestError(http.Request request, String code) =>
      http.Response(
        jsonEncode({
          'code': code,
          'message': 'boom',
          'details': '',
          'hint': null,
        }),
        code == '42501' ? 403 : 400,
        request: request,
        headers: {'content-type': 'application/json; charset=utf-8'},
      );

  /// Postgrest serializes a single-row upsert as a bare object (a list when it
  /// batches several rows); the connector always uploads one row per op.
  Map<String, dynamic> upsertedRow(http.Request request) {
    final body = jsonDecode(request.body);
    return (body is List ? body.single : body) as Map<String, dynamic>;
  }

  group('fetchCredentials', () {
    test('devuelve null cuando no hay sesión (local-first, no es error)',
        () async {
      final supabase = await buildSupabase();
      final connector = PowerSyncConnector(supabase, buildCrashReporter());

      expect(await connector.fetchCredentials(), isNull);
    });

    test(
      'devuelve endpoint, token y userId de la sesión activa',
      () async {
        final supabase = await buildSupabase(signedInUserId: 'user-1');
        final connector = PowerSyncConnector(supabase, buildCrashReporter());

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
        final supabase = await buildSupabase(signedInUserId: 'user-1');
        final connector = PowerSyncConnector(supabase, buildCrashReporter());

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
    test('retorna sin tocar la red cuando la cola está vacía', () async {
      var requests = 0;
      final supabase = await buildSupabase(
        signedInUserId: 'user-1',
        responder: (request) {
          requests++;
          return http.Response('', 201, request: request);
        },
      );
      final crash = buildCrashReporter();
      final db = await openDatabase();
      final connector = PowerSyncConnector(supabase, crash);

      await connector.uploadData(db);

      expect(requests, 0);
      verifyZeroInteractions(crash);
    });

    test(
        'REGRESIÓN: un put sin user_id sube estampado con el id de la sesión '
        '(sin esto Postgres responde 42501 y la fila se pierde en silencio)',
        () async {
      Map<String, dynamic>? uploaded;
      final supabase = await buildSupabase(
        signedInUserId: 'user-1',
        responder: (request) {
          expect(request.method, 'POST');
          expect(request.url.path, '/rest/v1/transactions');
          uploaded = upsertedRow(request);
          return http.Response('', 201, request: request);
        },
      );
      final crash = buildCrashReporter();
      final db = await openDatabase();
      await db.execute(
        'INSERT INTO transactions(id, amount_minor, type, updated_at) '
        "VALUES('tx-1', 1234, 'expense', 1700000000000)",
      );
      final connector = PowerSyncConnector(supabase, crash);

      await connector.uploadData(db);

      expect(uploaded, isNotNull);
      expect(uploaded!['id'], 'tx-1');
      expect(uploaded!['user_id'], 'user-1');
      // Dinero: entero en unidades menores, jamás double.
      expect(uploaded!['amount_minor'], 1234);
      expect(uploaded!['amount_minor'], isA<int>());
      expect(uploaded!['updated_at'], 1700000000000);
      // La op se consumió de la cola local.
      expect(await queuedOps(db), 0);
      verifyZeroInteractions(crash);
    });

    test('un put con user_id ajeno NO es pisado por el de la sesión', () async {
      Map<String, dynamic>? uploaded;
      final supabase = await buildSupabase(
        signedInUserId: 'user-1',
        responder: (request) {
          uploaded = upsertedRow(request);
          return http.Response('', 201, request: request);
        },
      );
      final db = await openDatabase();
      await db.execute(
        'INSERT INTO budgets(id, user_id) VALUES(?, ?)',
        ['b-1', 'other-user'],
      );
      final connector = PowerSyncConnector(supabase, buildCrashReporter());

      await connector.uploadData(db);

      expect(uploaded!['user_id'], 'other-user');
      expect(uploaded!['id'], 'b-1');
    });

    test('un put con user_id explícitamente null sí se estampa', () async {
      Map<String, dynamic>? uploaded;
      final supabase = await buildSupabase(
        signedInUserId: 'user-1',
        responder: (request) {
          uploaded = upsertedRow(request);
          return http.Response('', 201, request: request);
        },
      );
      final db = await openDatabase();
      await enqueueRawOp(
        db,
        op: 'PUT',
        table: 'categories',
        id: 'c-1',
        data: {'name': 'Comida', 'user_id': null},
      );
      final connector = PowerSyncConnector(supabase, buildCrashReporter());

      await connector.uploadData(db);

      expect(uploaded!['user_id'], 'user-1');
      expect(uploaded!['name'], 'Comida');
    });

    test('sin sesión activa no inventa ningún user_id', () async {
      Map<String, dynamic>? uploaded;
      final supabase = await buildSupabase(
        responder: (request) {
          uploaded = upsertedRow(request);
          return http.Response('', 201, request: request);
        },
      );
      final db = await openDatabase();
      await db.execute(
        "INSERT INTO app_settings(id, updated_at) VALUES('s-1', 1700000000000)",
      );
      final connector = PowerSyncConnector(supabase, buildCrashReporter());

      await connector.uploadData(db);

      expect(uploaded, isNotNull);
      expect(uploaded!.containsKey('user_id'), isFalse);
      expect(uploaded!['id'], 's-1');
    });

    test('un put sin opData igual sube el id y el user_id de la sesión',
        () async {
      Map<String, dynamic>? uploaded;
      final supabase = await buildSupabase(
        signedInUserId: 'user-1',
        responder: (request) {
          uploaded = upsertedRow(request);
          return http.Response('', 201, request: request);
        },
      );
      final db = await openDatabase();
      await enqueueRawOp(
        db,
        op: 'PUT',
        table: 'scheduled_payments',
        id: 'sp-1',
      );
      final connector = PowerSyncConnector(supabase, buildCrashReporter());

      await connector.uploadData(db);

      expect(uploaded, {'id': 'sp-1', 'user_id': 'user-1'});
    });

    test('un patch actualiza por id y NO estampa user_id', () async {
      final requests = <http.Request>[];
      final supabase = await buildSupabase(
        signedInUserId: 'user-1',
        responder: (request) {
          requests.add(request);
          return http.Response('', 204, request: request);
        },
      );
      final db = await openDatabase();
      await db.execute(
        "INSERT INTO transactions(id, amount_minor) VALUES('tx-1', 1234)",
      );
      final connector = PowerSyncConnector(supabase, buildCrashReporter());
      await connector.uploadData(db); // consume el PUT inicial
      requests.clear();
      await db.execute(
        "UPDATE transactions SET amount_minor = 999 WHERE id = 'tx-1'",
      );

      await connector.uploadData(db);

      final patch = requests.single;
      expect(patch.method, 'PATCH');
      expect(patch.url.path, '/rest/v1/transactions');
      expect(patch.url.queryParameters['id'], 'eq.tx-1');
      expect(jsonDecode(patch.body), {'amount_minor': 999});
      expect(await queuedOps(db), 0);
    });

    test('un patch con opData vacío no llama a Postgres pero sí completa',
        () async {
      var requests = 0;
      final supabase = await buildSupabase(
        signedInUserId: 'user-1',
        responder: (request) {
          requests++;
          return http.Response('', 204, request: request);
        },
      );
      final db = await openDatabase();
      await enqueueRawOp(
        db,
        op: 'PATCH',
        table: 'budgets',
        id: 'b-1',
        data: <String, dynamic>{},
      );
      final connector = PowerSyncConnector(supabase, buildCrashReporter());

      await connector.uploadData(db);

      expect(requests, 0);
      expect(await queuedOps(db), 0);
    });

    test('un delete borra por id', () async {
      final requests = <http.Request>[];
      final supabase = await buildSupabase(
        signedInUserId: 'user-1',
        responder: (request) {
          requests.add(request);
          return http.Response('', 204, request: request);
        },
      );
      final db = await openDatabase();
      await db.execute("INSERT INTO categories(id) VALUES('c-1')");
      final connector = PowerSyncConnector(supabase, buildCrashReporter());
      await connector.uploadData(db); // consume el PUT inicial
      requests.clear();
      await db.execute("DELETE FROM categories WHERE id = 'c-1'");

      await connector.uploadData(db);

      final delete = requests.single;
      expect(delete.method, 'DELETE');
      expect(delete.url.path, '/rest/v1/categories');
      expect(delete.url.queryParameters['id'], 'eq.c-1');
      expect(await queuedOps(db), 0);
    });

    for (final code in ['42501', '23503', '22007']) {
      test(
          'un error fatal $code se reporta al CrashReporter y descarta la op '
          '(nunca se pierde en silencio)', () async {
        final supabase = await buildSupabase(
          signedInUserId: 'user-1',
          responder: (request) => postgrestError(request, code),
        );
        final crash = buildCrashReporter();
        final db = await openDatabase();
        await db.execute(
          "INSERT INTO transactions(id, amount_minor) VALUES('tx-1', 1234)",
        );
        final connector = PowerSyncConnector(supabase, crash);

        await connector.uploadData(db);

        final captured = verify(
          () => crash.recordError(
            captureAny(),
            captureAny(),
            context: captureAny(named: 'context'),
          ),
        ).captured;
        expect(captured[0], isA<PostgrestException>());
        expect((captured[0] as PostgrestException).code, code);
        expect(captured[1], isA<StackTrace>());
        expect(captured[2], allOf(isA<String>(), contains(code)));
        expect(await queuedOps(db), 0);
      });
    }

    for (final code in ['08006', '57014']) {
      test(
          'un error transitorio $code se relanza, no se reporta y deja la op '
          'en la cola para reintento', () async {
        final supabase = await buildSupabase(
          signedInUserId: 'user-1',
          responder: (request) => postgrestError(request, code),
        );
        final crash = buildCrashReporter();
        final db = await openDatabase();
        await db.execute(
          "INSERT INTO transactions(id, amount_minor) VALUES('tx-1', 1234)",
        );
        final connector = PowerSyncConnector(supabase, crash);

        await expectLater(
          connector.uploadData(db),
          throwsA(isA<PostgrestException>()),
        );

        expect(await queuedOps(db), 1);
        verifyNever(
          () => crash.recordError(
            any(),
            any(),
            context: any(named: 'context'),
            fatal: any(named: 'fatal'),
          ),
        );
      });
    }

    test('un error fatal aborta las ops restantes de la misma transacción',
        () async {
      final paths = <String>[];
      final supabase = await buildSupabase(
        signedInUserId: 'user-1',
        responder: (request) {
          paths.add(request.url.path);
          if (request.url.path.endsWith('transactions')) {
            return postgrestError(request, '42501');
          }
          return http.Response('', 201, request: request);
        },
      );
      final crash = buildCrashReporter();
      final db = await openDatabase();
      await db.writeTransaction((tx) async {
        await tx.execute(
          "INSERT INTO transactions(id, amount_minor) VALUES('tx-1', 1234)",
        );
        await tx.execute("INSERT INTO budgets(id) VALUES('b-1')");
      });
      final connector = PowerSyncConnector(supabase, crash);

      await connector.uploadData(db);

      expect(paths, ['/rest/v1/transactions']);
      // Toda la transacción se descarta junto con la op fatal.
      expect(await queuedOps(db), 0);
    });
  });
}
