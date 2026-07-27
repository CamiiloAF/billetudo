import 'dart:convert';

import 'package:billetudo/features/auth/data/datasources/seed_category_ownership_remote_datasource.dart';
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

  test('devuelve lista vacía sin llamar a Postgres cuando no hay seedIds',
      () async {
    var called = false;
    final supabase = await buildClient((request) {
      called = true;
      return http.Response('[]', 200, request: request);
    });
    final datasource = SeedCategoryOwnershipRemoteDatasource(supabase);

    final result = await datasource.existingSeedCategoryIds('user-1', []);

    expect(result, isEmpty);
    expect(called, isFalse);
  });

  test(
      'HU-04: devuelve los ids que la cuenta ya tiene sembrados '
      '(docs/requirements/05-auth-sync.md, decisión #12)', () async {
    final supabase = await buildClient((request) {
      expect(request.url.path, contains('/rest/v1/categories'));
      expect(request.url.queryParameters['user_id'], 'eq.user-1');
      return http.Response(
        jsonEncode([
          {'id': 'seed-food-drink'},
        ]),
        200,
        request: request,
        headers: {'content-type': 'application/json'},
      );
    });
    final datasource = SeedCategoryOwnershipRemoteDatasource(supabase);

    final result = await datasource.existingSeedCategoryIds(
      'user-1',
      ['seed-food-drink', 'seed-transport'],
    );

    expect(result, ['seed-food-drink']);
  });

  test('propaga un fallo de red como SeedCategoryOwnershipCheckException',
      () async {
    final supabase = await buildClient(
      (request) => http.Response('boom', 500, request: request),
    );
    final datasource = SeedCategoryOwnershipRemoteDatasource(supabase);

    expect(
      () => datasource.existingSeedCategoryIds('user-1', ['seed-food-drink']),
      throwsA(isA<SeedCategoryOwnershipCheckException>()),
    );
  });
}
