import 'package:billetudo/core/database/app_database.dart';
import 'package:billetudo/core/error/result.dart';
import 'package:billetudo/core/sync/data/datasources/backup_id_collision_datasource.dart';
import 'package:billetudo/features/auth/data/datasources/local_data_ownership_datasource.dart';
import 'package:billetudo/features/auth/data/datasources/seed_category_ownership_remote_datasource.dart';
import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockSeedCategoryOwnershipRemoteDatasource extends Mock
    implements SeedCategoryOwnershipRemoteDatasource {}

class MockBackupIdCollisionDatasource extends Mock
    implements BackupIdCollisionDatasource {}

void main() {
  late AppDatabase db;
  late MockSeedCategoryOwnershipRemoteDatasource seedOwnership;
  late MockBackupIdCollisionDatasource collisionDatasource;
  late LocalDataOwnershipDatasource datasource;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    seedOwnership = MockSeedCategoryOwnershipRemoteDatasource();
    collisionDatasource = MockBackupIdCollisionDatasource();
    datasource =
        LocalDataOwnershipDatasource(db, seedOwnership, collisionDatasource);
    registerFallbackValue(<String>[]);
    registerFallbackValue(<BackupRowId>[]);
  });

  tearDown(() async => db.close());

  Future<void> insertCategory(
    String id, {
    bool asSeed = true,
    String? parentId,
  }) =>
      db.into(db.categories).insert(
            CategoriesCompanion.insert(
              id: asSeed ? Value(id) : const Value.absent(),
              name: id,
              kind: CategoryKind.expense,
              parentId: Value(parentId),
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

  test('reclama normal una categoría seed que la cuenta nunca había sembrado',
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
      'reclama categorías en orden topológico (padre antes que hijo antes '
      'que nieto), evitando el 23503 de la FK compuesta de Postgres',
      () async {
    // Insert child-before-parent on purpose: the bug this guards against is
    // triggered by SQLite's own scan order, which has nothing to do with
    // insertion order, but inserting them "wrong" first makes sure the fix
    // isn't accidentally relying on insertion order either.
    await insertCategory('grandchild', parentId: 'child');
    await insertCategory('child', parentId: 'root');
    await insertCategory('root');
    when(() => seedOwnership.existingSeedCategoryIds(any(), any()))
        .thenAnswer((_) async => const []);

    // A trigger-backed log is the only way to observe the *order* the
    // individual `UPDATE ... WHERE id = ?` statements actually ran in — SQL
    // `UPDATE` never reorders rows, so `rowid`/insertion order cannot tell
    // parent-before-child apart from child-before-parent after the fact.
    await db.customStatement(
      'CREATE TABLE claim_log (seq INTEGER PRIMARY KEY AUTOINCREMENT, '
      'category_id TEXT)',
    );
    await db.customStatement(
      'CREATE TRIGGER claim_log_trigger AFTER UPDATE OF user_id ON '
      'categories WHEN NEW.user_id IS NOT NULL '
      'BEGIN INSERT INTO claim_log (category_id) VALUES (NEW.id); END',
    );

    final result = await datasource.claimUnownedRows('user-1');

    expect(result.isRight(), isTrue);
    final rows = {
      for (final row in await db.select(db.categories).get())
        row.id: row.userId,
    };
    expect(rows['root'], 'user-1');
    expect(rows['child'], 'user-1');
    expect(rows['grandchild'], 'user-1');

    final log = await db
        .customSelect('SELECT category_id FROM claim_log ORDER BY seq')
        .get();
    final claimOrder =
        [for (final row in log) row.read<String>('category_id')];
    expect(claimOrder, ['root', 'child', 'grandchild']);
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

  group('findCollidingIds — BackupIdCollisionResolver', () {
    test('no llama a Postgres cuando idsByTable está vacío', () async {
      final result = await datasource.findCollidingIds(
        userId: 'user-1',
        idsByTable: const {},
      );

      expect(result.getRight().toNullable(), isEmpty);
      verifyNever(() => collisionDatasource.findCollidingIds(any(), any()));
    });

    test('delega en BackupIdCollisionDatasource y devuelve la colisión',
        () async {
      when(() => collisionDatasource.findCollidingIds('user-1', any()))
          .thenAnswer((_) async => {
                'transactions': ['tx-1'],
              });

      final result = await datasource.findCollidingIds(
        userId: 'user-1',
        idsByTable: {
          'transactions': ['tx-1', 'tx-2'],
        },
      );

      expect(
        result.getRight().toNullable(),
        {
          'transactions': ['tx-1'],
        },
      );
      final captured = verify(
        () => collisionDatasource.findCollidingIds('user-1', captureAny()),
      ).captured.single as List<BackupRowId>;
      expect(captured, hasLength(2));
      expect(captured.map((r) => r.tableName), everyElement('transactions'));
      expect(captured.map((r) => r.id), ['tx-1', 'tx-2']);
    });

    test(
        'propaga NetworkFailure fail-closed cuando el chequeo de colisión '
        'falla por red', () async {
      when(() => collisionDatasource.findCollidingIds('user-1', any()))
          .thenThrow(const BackupIdCollisionCheckException('sin red'));

      final result = await datasource.findCollidingIds(
        userId: 'user-1',
        idsByTable: {
          'transactions': ['tx-1'],
        },
      );

      expect(result.getLeft().toNullable(), isA<NetworkFailure>());
    });
  });
}
