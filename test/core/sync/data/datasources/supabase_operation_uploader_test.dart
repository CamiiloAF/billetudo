import 'dart:convert';

import 'package:billetudo/core/sync/data/datasources/supabase_operation_uploader.dart';
import 'package:billetudo/core/sync/domain/entities/sync_operation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Supabase is faked at the HTTP layer (`MockClient`), the same pattern used
/// in `seed_category_ownership_remote_datasource_test.dart`: what matters here
/// is the exact request PostgREST receives, and that the backend rejection is
/// rethrown untouched so `SyncErrorClassifier` — not this class — decides what
/// it means.
void main() {
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

  /// Postgrest serializes a single-row upsert as a bare object (a list when it
  /// batches several rows); the uploader always sends one row per operation.
  Map<String, dynamic> upsertedRow(http.Request request) {
    final body = jsonDecode(request.body);
    return (body is List ? body.single : body) as Map<String, dynamic>;
  }

  group('put', () {
    test(
        'REGRESIÓN: un put sin user_id sube estampado con el id de la sesión '
        '(sin esto Postgres responde 42501 y la fila nunca llega)', () async {
      http.Request? seen;
      final supabase = await buildSupabase(
        signedInUserId: 'user-1',
        responder: (request) {
          seen = request;
          return http.Response('', 201, request: request);
        },
      );

      await SupabaseOperationUploader(supabase).upload(
        const SyncOperation(
          tableName: 'transactions',
          rowId: 'tx-1',
          type: SyncOperationType.put,
          payload: <String, dynamic>{
            'amount_minor': 1234,
            'updated_at': 1700000000000,
          },
        ),
      );

      expect(seen!.method, 'POST');
      expect(seen!.url.path, '/rest/v1/transactions');
      final row = upsertedRow(seen!);
      expect(row['id'], 'tx-1');
      expect(row['user_id'], 'user-1');
      // Dinero: entero en unidades menores, jamás double.
      expect(row['amount_minor'], 1234);
      expect(row['amount_minor'], isA<int>());
      expect(row['updated_at'], 1700000000000);
    });

    test('un user_id ajeno NO es pisado por el de la sesión', () async {
      http.Request? seen;
      final supabase = await buildSupabase(
        signedInUserId: 'user-1',
        responder: (request) {
          seen = request;
          return http.Response('', 201, request: request);
        },
      );

      await SupabaseOperationUploader(supabase).upload(
        const SyncOperation(
          tableName: 'budgets',
          rowId: 'b-1',
          type: SyncOperationType.put,
          payload: <String, dynamic>{'user_id': 'other-user'},
        ),
      );

      expect(upsertedRow(seen!)['user_id'], 'other-user');
      expect(upsertedRow(seen!)['id'], 'b-1');
    });

    test('un user_id explícitamente null sí se estampa', () async {
      http.Request? seen;
      final supabase = await buildSupabase(
        signedInUserId: 'user-1',
        responder: (request) {
          seen = request;
          return http.Response('', 201, request: request);
        },
      );

      await SupabaseOperationUploader(supabase).upload(
        const SyncOperation(
          tableName: 'categories',
          rowId: 'c-1',
          type: SyncOperationType.put,
          payload: <String, dynamic>{'name': 'Comida', 'user_id': null},
        ),
      );

      expect(upsertedRow(seen!)['user_id'], 'user-1');
      expect(upsertedRow(seen!)['name'], 'Comida');
    });

    test('sin sesión activa no inventa ningún user_id', () async {
      http.Request? seen;
      final supabase = await buildSupabase(
        responder: (request) {
          seen = request;
          return http.Response('', 201, request: request);
        },
      );

      await SupabaseOperationUploader(supabase).upload(
        const SyncOperation(
          tableName: 'app_settings',
          rowId: 's-1',
          type: SyncOperationType.put,
          payload: <String, dynamic>{'updated_at': 1700000000000},
        ),
      );

      final row = upsertedRow(seen!);
      expect(row.containsKey('user_id'), isFalse);
      expect(row['id'], 's-1');
    });

    test('un put sin payload igual sube el id y el user_id de la sesión',
        () async {
      http.Request? seen;
      final supabase = await buildSupabase(
        signedInUserId: 'user-1',
        responder: (request) {
          seen = request;
          return http.Response('', 201, request: request);
        },
      );

      await SupabaseOperationUploader(supabase).upload(
        const SyncOperation(
          tableName: 'scheduled_payments',
          rowId: 'sp-1',
          type: SyncOperationType.put,
        ),
      );

      expect(upsertedRow(seen!), {'id': 'sp-1', 'user_id': 'user-1'});
    });
  });

  group('patch', () {
    test('actualiza por id y NO estampa user_id', () async {
      http.Request? seen;
      final supabase = await buildSupabase(
        signedInUserId: 'user-1',
        responder: (request) {
          seen = request;
          return http.Response('', 204, request: request);
        },
      );

      await SupabaseOperationUploader(supabase).upload(
        const SyncOperation(
          tableName: 'transactions',
          rowId: 'tx-1',
          type: SyncOperationType.patch,
          payload: <String, dynamic>{'amount_minor': 999},
        ),
      );

      expect(seen!.method, 'PATCH');
      expect(seen!.url.path, '/rest/v1/transactions');
      expect(seen!.url.queryParameters['id'], 'eq.tx-1');
      expect(jsonDecode(seen!.body), {'amount_minor': 999});
    });

    for (final payload in <Map<String, dynamic>?>[null, <String, dynamic>{}]) {
      test(
          'un patch con payload ${payload == null ? 'nulo' : 'vacío'} no '
          'llama a Postgres', () async {
        var requests = 0;
        final supabase = await buildSupabase(
          signedInUserId: 'user-1',
          responder: (request) {
            requests++;
            return http.Response('', 204, request: request);
          },
        );

        await SupabaseOperationUploader(supabase).upload(
          SyncOperation(
            tableName: 'budgets',
            rowId: 'b-1',
            type: SyncOperationType.patch,
            payload: payload,
          ),
        );

        expect(requests, 0);
      });
    }
  });

  group('delete', () {
    test('borra por id', () async {
      http.Request? seen;
      final supabase = await buildSupabase(
        signedInUserId: 'user-1',
        responder: (request) {
          seen = request;
          return http.Response('', 204, request: request);
        },
      );

      await SupabaseOperationUploader(supabase).upload(
        const SyncOperation(
          tableName: 'categories',
          rowId: 'c-1',
          type: SyncOperationType.delete,
        ),
      );

      expect(seen!.method, 'DELETE');
      expect(seen!.url.path, '/rest/v1/categories');
      expect(seen!.url.queryParameters['id'], 'eq.c-1');
    });
  });

  test(
      'el rechazo del backend se relanza tal cual: clasificarlo es tarea del '
      'llamador, no de este uploader', () async {
    final supabase = await buildSupabase(
      signedInUserId: 'user-1',
      responder: (request) => http.Response(
        jsonEncode({
          'code': 'PGRST204',
          'message': "Could not find the 'closed_at' column of 'debts' "
              'in the schema cache',
          'details': '',
          'hint': null,
        }),
        400,
        request: request,
        headers: {'content-type': 'application/json; charset=utf-8'},
      ),
    );

    await expectLater(
      SupabaseOperationUploader(supabase).upload(
        const SyncOperation(
          tableName: 'debts',
          rowId: 'd-1',
          type: SyncOperationType.put,
        ),
      ),
      throwsA(
        isA<PostgrestException>().having((e) => e.code, 'code', 'PGRST204'),
      ),
    );
  });
}
