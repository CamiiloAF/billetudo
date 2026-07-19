import 'package:billetudo/core/database/app_database.dart';
import 'package:billetudo/core/error/result.dart';
import 'package:billetudo/features/auth/data/datasources/local_data_ownership_datasource.dart';
import 'package:billetudo/features/auth/data/datasources/seed_category_ownership_remote_datasource.dart';
import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockSeedCategoryOwnershipRemoteDatasource extends Mock
    implements SeedCategoryOwnershipRemoteDatasource {}

void main() {
  late AppDatabase db;
  late MockSeedCategoryOwnershipRemoteDatasource seedOwnership;
  late LocalDataOwnershipDatasource datasource;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    seedOwnership = MockSeedCategoryOwnershipRemoteDatasource();
    datasource = LocalDataOwnershipDatasource(db, seedOwnership);
    registerFallbackValue(<String>[]);
  });

  tearDown(() async => db.close());

  Future<void> insertCategory(String id, {bool asSeed = true}) =>
      db.into(db.categories).insert(
            CategoriesCompanion.insert(
              id: asSeed ? Value(id) : const Value.absent(),
              name: id,
              kind: CategoryKind.expense,
            ),
          );

  Future<void> insertAccount(String name) => db.into(db.accounts).insert(
        AccountsCompanion.insert(
          name: name,
          type: AccountType.bank,
          currency: 'COP',
        ),
      );

  test(
      'HU-04: reclama toda fila sin dueño de las 12 tablas cuando no hay '
      'categorías seed locales', () async {
    await insertAccount('Efectivo');
    when(() => seedOwnership.existingSeedCategoryIds(any(), any()))
        .thenAnswer((_) async => const []);

    final result = await datasource.claimUnownedRows('user-1');

    expect(result.isRight(), isTrue);
    final account = await db.select(db.accounts).getSingle();
    expect(account.userId, 'user-1');
    verifyNever(() => seedOwnership.existingSeedCategoryIds(any(), any()));
  });

  test(
      'HU-04 decisión #12: NO reclama una categoría seed que la cuenta ya '
      'tenía sembrada en la nube', () async {
    await insertCategory('seed-food-drink');
    await insertCategory('seed-transport');
    when(() => seedOwnership.existingSeedCategoryIds('user-1', any()))
        .thenAnswer((_) async => ['seed-food-drink']);

    final result = await datasource.claimUnownedRows('user-1');

    expect(result.isRight(), isTrue);
    final rows = {
      for (final row in await db.select(db.categories).get())
        row.id: row.userId,
    };
    expect(rows['seed-food-drink'], isNull);
    expect(rows['seed-transport'], 'user-1');
  });

  test(
      'reclama normal una categoría seed que la cuenta nunca había sembrado',
      () async {
    await insertCategory('seed-food-drink');
    when(() => seedOwnership.existingSeedCategoryIds('user-1', any()))
        .thenAnswer((_) async => const []);

    final result = await datasource.claimUnownedRows('user-1');

    expect(result.isRight(), isTrue);
    final row = await db.select(db.categories).getSingle();
    expect(row.userId, 'user-1');
  });

  test('reclama normal una categoría creada a mano (id no-seed)', () async {
    await insertCategory('user-made-id', asSeed: false);
    when(() => seedOwnership.existingSeedCategoryIds(any(), any()))
        .thenAnswer((_) async => const []);

    final result = await datasource.claimUnownedRows('user-1');

    expect(result.isRight(), isTrue);
    final row = await db.select(db.categories).getSingle();
    expect(row.userId, 'user-1');
    verifyNever(() => seedOwnership.existingSeedCategoryIds(any(), any()));
  });

  test(
      'propaga NetworkFailure sin reclamar nada cuando el chequeo de '
      'Postgres falla', () async {
    await insertAccount('Efectivo');
    await insertCategory('seed-food-drink');
    when(() => seedOwnership.existingSeedCategoryIds('user-1', any()))
        .thenThrow(const SeedCategoryOwnershipCheckException('sin red'));

    final result = await datasource.claimUnownedRows('user-1');

    expect(result.getLeft().toNullable(), isA<NetworkFailure>());
    final account = await db.select(db.accounts).getSingle();
    expect(account.userId, isNull);
    final category = await db.select(db.categories).getSingle();
    expect(category.userId, isNull);
  });
}
