import 'dart:convert';

import 'package:billetudo/core/sync/data/datasources/backup_id_collision_datasource.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  Future<SupabaseClient> buildClient(
    http.Response Function(http.Request request) responder,
  ) async {
    final client = SupabaseClient(
      'https://example.supabase.co',
      'anon-key',
      httpClient: MockClient((request) async => responder(request)),
    );
    addTearDown(client.dispose);
    return client;
  }

  test('no llama a Postgres cuando no hay filas que chequear', () async {
    var called = false;
    final supabase = await buildClient((request) {
      called = true;
      return http.Response('[]', 200, request: request);
    });
    final datasource = BackupIdCollisionDatasource(supabase);

    final result = await datasource.findCollidingIds('user-1', const []);

    expect(result, isEmpty);
    expect(called, isFalse);
  });

  test(
      'convierte los nombres de tabla camelCase a snake_case antes de la RPC '
      'y de vuelta al devolver el resultado', () async {
    final supabase = await buildClient((request) {
      expect(request.url.path, contains('/rest/v1/rpc/'
          'check_backup_restore_id_collisions'));
      final body = jsonDecode(request.body) as Map<String, dynamic>;
      expect(body['p_user_id'], 'user-1');
      final rows = body['p_rows'] as List<dynamic>;
      expect(rows, [
        {'table_name': 'goal_contributions', 'id': 'gc-1'},
      ]);
      return http.Response(
        jsonEncode([
          {'table_name': 'goal_contributions', 'id': 'gc-1'},
        ]),
        200,
        request: request,
        headers: {'content-type': 'application/json'},
      );
    });
    final datasource = BackupIdCollisionDatasource(supabase);

    final result = await datasource.findCollidingIds(
      'user-1',
      const [BackupRowId(tableName: 'goalContributions', id: 'gc-1')],
    );

    expect(result, {
      'goalContributions': ['gc-1'],
    });
  });

  test('devuelve solo el subconjunto de ids en colisión, no todos los enviados',
      () async {
    final supabase = await buildClient((request) {
      return http.Response(
        jsonEncode([
          {'table_name': 'transactions', 'id': 'tx-1'},
        ]),
        200,
        request: request,
        headers: {'content-type': 'application/json'},
      );
    });
    final datasource = BackupIdCollisionDatasource(supabase);

    final result = await datasource.findCollidingIds(
      'user-1',
      const [
        BackupRowId(tableName: 'transactions', id: 'tx-1'),
        BackupRowId(tableName: 'transactions', id: 'tx-2'),
      ],
    );

    expect(result, {
      'transactions': ['tx-1'],
    });
  });

  test('propaga un fallo de red como BackupIdCollisionCheckException',
      () async {
    final supabase = await buildClient(
      (request) => http.Response('boom', 500, request: request),
    );
    final datasource = BackupIdCollisionDatasource(supabase);

    expect(
      () => datasource.findCollidingIds(
        'user-1',
        const [BackupRowId(tableName: 'accounts', id: 'acc-1')],
      ),
      throwsA(isA<BackupIdCollisionCheckException>()),
    );
  });
}
