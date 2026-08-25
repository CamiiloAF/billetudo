import 'package:billetudo/core/database/app_database.dart';
import 'package:billetudo/features/auth/data/datasources/local_data_conflict_datasource.dart';
import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase db;
  late LocalDataConflictDatasource datasource;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    datasource = LocalDataConflictDatasource(db);
  });

  tearDown(() async => db.close());

  Future<void> insertAccount({String? userId, String name = 'Efectivo'}) =>
      db.into(db.accounts).insert(
            AccountsCompanion.insert(
              name: name,
              type: AccountType.bank,
              currency: 'COP',
              userId: Value(userId),
            ),
          );

  Future<void> insertCategory({String? userId, String? id}) =>
      db.into(db.categories).insert(
            CategoriesCompanion.insert(
              id: id != null ? Value(id) : const Value.absent(),
              name: id ?? 'Comida',
              kind: CategoryKind.expense,
              userId: Value(userId),
            ),
          );

  test(
      'devuelve false cuando este dispositivo no tiene ninguna fila '
      'marcada con user_id', () async {
    await insertAccount();

    final hasConflict = await datasource.hasConflict('user-incoming');

    expect(hasConflict, isFalse);
  });

  test(
      'devuelve true cuando cualquier tabla de la lista compartida tiene una '
      'fila con user_id distinto al entrante', () async {
    await insertAccount(userId: 'user-owner');

    final hasConflict = await datasource.hasConflict('user-incoming');

    expect(hasConflict, isTrue);
  });

  test(
      'HU-04: las filas con user_id IS NULL nunca disparan un conflicto '
      '(ese es el territorio del merge de HU-04, no de esta detección)',
      () async {
    await insertAccount();
    await insertCategory();

    final hasConflict = await datasource.hasConflict('user-incoming');

    expect(hasConflict, isFalse);
  });

  test(
      'un dispositivo ya asociado a la MISMA cuenta que inicia sesión nunca '
      'dispara la hoja', () async {
    await insertAccount(userId: 'user-incoming');
    await insertCategory(userId: 'user-incoming');

    final hasConflict = await datasource.hasConflict('user-incoming');

    expect(hasConflict, isFalse);
  });

  test('revisa cada tabla de la lista compartida, no solo accounts',
      () async {
    await insertCategory(userId: 'user-owner');

    final hasConflict = await datasource.hasConflict('user-incoming');

    expect(hasConflict, isTrue);
  });

  test('propaga la excepción de lectura en vez de tragarla (fail-closed)',
      () async {
    // Rompe la primera tabla de la lista compartida a propósito: el SELECT
    // sobre ella debe fallar y esa excepción debe escapar sin ser atrapada.
    await db.customStatement('DROP TABLE accounts');

    await expectLater(
      datasource.hasConflict('user-incoming'),
      throwsA(anything),
    );
  });
}
