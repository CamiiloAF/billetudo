import 'dart:convert';

import 'package:billetudo/core/database/app_database.dart' as db;
import 'package:billetudo/features/categories/data/datasources/category_seeds_remote_datasource.dart';
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

  test(
      'HU-06: mapea las filas de category_seeds a CategorySeedEntry '
      '(docs/requirements/05-auth-sync.md, decisión #12)', () async {
    final supabase = await buildClient((request) {
      expect(request.url.path, contains('/rest/v1/category_seeds'));
      return http.Response(
        jsonEncode([
          {
            'id': 'seed-food-drink',
            'kind': 'expense',
            'parent_id': null,
            'name_es': 'Comida y bebida',
            'name_en': 'Food & drink',
            'icon': 'utensils',
            'color': 'mint',
            'sort_order': 0,
          },
          {
            'id': 'seed-salary',
            'kind': 'income',
            'parent_id': null,
            'name_es': 'Salario',
            'name_en': 'Salary',
            'icon': 'banknote',
            'color': null,
            'sort_order': 0,
          },
        ]),
        200,
        request: request,
        headers: {'content-type': 'application/json'},
      );
    });
    final datasource = CategorySeedsRemoteDatasource(supabase);

    final catalog = await datasource.fetchCatalog();

    expect(catalog, hasLength(2));
    final food = catalog.singleWhere((e) => e.id == 'seed-food-drink');
    expect(food.kind, db.CategoryKind.expense);
    expect(food.parentId, isNull);
    expect(food.nameEs, 'Comida y bebida');
    expect(food.nameEn, 'Food & drink');
    expect(food.icon, 'utensils');
    expect(food.color, 'mint');

    final salary = catalog.singleWhere((e) => e.id == 'seed-salary');
    expect(salary.kind, db.CategoryKind.income);
    expect(salary.color, isNull);
  });

  test('propaga un fallo de red como CategorySeedsFetchException', () async {
    final supabase = await buildClient(
      (request) => http.Response('boom', 500, request: request),
    );
    final datasource = CategorySeedsRemoteDatasource(supabase);

    expect(
      datasource.fetchCatalog,
      throwsA(isA<CategorySeedsFetchException>()),
    );
  });
}
