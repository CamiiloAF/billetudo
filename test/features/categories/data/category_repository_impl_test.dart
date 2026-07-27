import 'package:billetudo/core/database/app_database.dart' as db;
import 'package:billetudo/core/error/result.dart';
import 'package:billetudo/features/categories/data/datasources/categories_local_datasource.dart';
import 'package:billetudo/features/categories/data/datasources/category_seeds_remote_datasource.dart';
import 'package:billetudo/features/categories/data/models/category_seed_entry.dart';
import 'package:billetudo/features/categories/data/repositories/category_repository_impl.dart';
import 'package:billetudo/features/categories/domain/entities/category.dart';
import 'package:billetudo/features/categories/domain/entities/category_draft.dart';
import 'package:drift/drift.dart' as drift;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockCategorySeedsRemoteDatasource extends Mock
    implements CategorySeedsRemoteDatasource {}

void main() {
  late db.AppDatabase database;
  late MockCategorySeedsRemoteDatasource remoteSeeds;
  late CategoryRepositoryImpl repository;

  final fakeCatalog = [
    const CategorySeedEntry(
      id: 'seed-food-drink',
      kind: db.CategoryKind.expense,
      parentId: null,
      nameEs: 'Comida y bebida',
      nameEn: 'Food & drink',
      icon: 'utensils',
      color: 'mint',
      sortOrder: 0,
    ),
  ];

  setUp(() {
    database = db.AppDatabase(NativeDatabase.memory());
    remoteSeeds = MockCategorySeedsRemoteDatasource();
    repository = CategoryRepositoryImpl(
      CategoriesLocalDatasource(database),
      remoteSeeds,
    );
  });

  tearDown(() async => database.close());

  Future<Category> createRoot(
    String name, {
    CategoryKind kind = CategoryKind.expense,
  }) async {
    final result = await repository.createCategory(
      CategoryDraft(name: name, kind: kind),
    );
    return result.getRight().toNullable()!;
  }

  group('createCategory', () {
    test('persiste con id UUID y sortOrder contiguo al final de su kind',
        () async {
      final first = await createRoot('Comida');
      final second = await createRoot('Transporte');

      expect(first.id, hasLength(36));
      expect(first.sortOrder, 0);
      expect(second.sortOrder, 1);
    });

    test('una subcategoría entra al final de los hijos de su padre', () async {
      final root = await createRoot('Comida');
      final sub1 = await repository
          .createCategory(
            CategoryDraft(
              name: 'Mercado',
              kind: CategoryKind.expense,
              parentId: root.id,
            ),
          )
          .then((r) => r.getRight().toNullable()!);
      final sub2 = await repository
          .createCategory(
            CategoryDraft(
              name: 'Restaurantes',
              kind: CategoryKind.expense,
              parentId: root.id,
            ),
          )
          .then((r) => r.getRight().toNullable()!);

      expect(sub1.sortOrder, 0);
      expect(sub2.sortOrder, 1);
      // No consume el sortOrder de las raíces.
      final third = await createRoot('Vivienda');
      expect(third.sortOrder, 1);
    });
  });

  group('updateCategory', () {
    test('sube updatedAt sin tocar createdAt', () async {
      final root = await createRoot('Comida');
      // `updatedAt` is epoch millis: back-date it so the comparison does not
      // depend on the test running in under a millisecond.
      final backdated = DateTime.now()
          .subtract(const Duration(minutes: 5))
          .millisecondsSinceEpoch;
      await (database.update(database.categories)
            ..where((c) => c.id.equals(root.id)))
          .write(db.CategoriesCompanion(updatedAt: drift.Value(backdated)));

      final result = await repository.updateCategory(
        CategoryDraft(id: root.id, name: 'Comida y bebida', kind: root.kind),
      );

      final updated = result.getRight().toNullable()!;
      expect(updated.name, 'Comida y bebida');
      expect(updated.createdAt, root.createdAt);
      expect(updated.updatedAt > backdated, isTrue);
    });

    test('actualizar una categoría inexistente es NotFound', () async {
      final result = await repository.updateCategory(
        const CategoryDraft(
          id: 'no-existe',
          name: 'X',
          kind: CategoryKind.expense,
        ),
      );

      expect(result.getLeft().toNullable(), isA<NotFoundFailure>());
    });
  });

  group('watchCategories', () {
    test('agrupa raíz -> subcategorías ordenadas por sortOrder', () async {
      final root = await createRoot('Comida');
      final sub = await repository
          .createCategory(
            CategoryDraft(
              name: 'Mercado',
              kind: CategoryKind.expense,
              parentId: root.id,
            ),
          )
          .then((r) => r.getRight().toNullable()!);

      final result =
          await repository.watchCategories(CategoryKind.expense).first;

      final nodes = result.getRight().toNullable()!;
      expect(nodes, hasLength(1));
      expect(nodes.single.root.id, root.id);
      expect(nodes.single.subcategories.single.id, sub.id);
    });

    test('una categoría eliminada desaparece del listado', () async {
      final root = await createRoot('Comida');
      await repository.softDeleteCategory(root.id);

      final result =
          await repository.watchCategories(CategoryKind.expense).first;

      expect(result.getRight().toNullable(), isEmpty);
    });
  });

  group('getDeletionImpact', () {
    test('reporta subcategorías activas y transacciones activas', () async {
      final root = await createRoot('Comida');
      await repository.createCategory(
        CategoryDraft(
          name: 'Mercado',
          kind: CategoryKind.expense,
          parentId: root.id,
        ),
      );
      final accountId = await database
          .into(database.accounts)
          .insertReturning(
            db.AccountsCompanion.insert(
              name: 'Cuenta',
              type: db.AccountType.bank,
              currency: 'COP',
            ),
          )
          .then((row) => row.id);
      await database.into(database.transactions).insert(
            db.TransactionsCompanion.insert(
              accountId: accountId,
              categoryId: drift.Value(root.id),
              amountMinor: 1000,
              currency: 'COP',
              type: db.EntryType.expense,
              date: DateTime(2026, 7, 10),
            ),
          );

      final result = await repository.getDeletionImpact(root.id);

      final impact = result.getRight().toNullable()!;
      expect(impact.hasActiveSubcategories, isTrue);
      expect(impact.transactionCount, 1);
    });
  });

  group('getActiveSubcategories', () {
    test('solo las subcategorías activas del padre, no las de otro padre',
        () async {
      final root = await createRoot('Comida');
      final otherRoot = await createRoot('Transporte');
      final sub1 = await repository
          .createCategory(
            CategoryDraft(
              name: 'Mercado',
              kind: CategoryKind.expense,
              parentId: root.id,
            ),
          )
          .then((r) => r.getRight().toNullable()!);
      await repository.createCategory(
        CategoryDraft(
          name: 'Bus',
          kind: CategoryKind.expense,
          parentId: otherRoot.id,
        ),
      );
      final sub2 = await repository
          .createCategory(
            CategoryDraft(
              name: 'Restaurantes',
              kind: CategoryKind.expense,
              parentId: root.id,
            ),
          )
          .then((r) => r.getRight().toNullable()!);
      await repository.softDeleteCategory(sub2.id);

      final result = await repository.getActiveSubcategories(root.id);

      final ids = result.getRight().toNullable()!.map((c) => c.id);
      expect(ids, [sub1.id]);
    });
  });

  group('softDeleteCategory / restoreCategory (HU-04)', () {
    test('el borrado es reversible vía deletedAt', () async {
      final root = await createRoot('Comida');

      await repository.softDeleteCategory(root.id);
      final afterDelete = await repository.getCategory(root.id);
      expect(afterDelete.getLeft().toNullable(), isA<NotFoundFailure>());

      final restore = await repository.restoreCategory(root.id);
      expect(restore.isRight(), isTrue);
      final afterRestore = await repository.getCategory(root.id);
      expect(afterRestore.isRight(), isTrue);
    });
  });

  group('reorderCategories (HU-05)', () {
    test('persiste sortOrder contiguo 0..n-1 en el orden dado', () async {
      final a = await createRoot('A');
      final b = await createRoot('B');
      final c = await createRoot('C');

      await repository.reorderCategories([b.id, c.id, a.id]);

      final result =
          await repository.watchCategories(CategoryKind.expense).first;
      final ids = result.getRight().toNullable()!.map((n) => n.root.id);
      expect(ids, [b.id, c.id, a.id]);
    });
  });

  group('hasAnyCategory / seedDefaultCategories (HU-06)', () {
    test('false sin categorías, true tras sembrar desde el catálogo remoto',
        () async {
      when(() => remoteSeeds.fetchCatalog())
          .thenAnswer((_) async => fakeCatalog);

      expect(
        (await repository.hasAnyCategory()).getRight().toNullable(),
        isFalse,
      );

      final seedResult = await repository.seedDefaultCategories();

      expect(seedResult.isRight(), isTrue);
      expect(
        (await repository.hasAnyCategory()).getRight().toNullable(),
        isTrue,
      );
      // The exact name picked (es/en) depends on `AppLocale.resolveLanguageCode`
      // — the device's own locale in this test environment — and is covered
      // by `CategoriesLocalDatasource`'s own seeding tests; here we only
      // assert it landed on one of the catalog's two translations.
      final seeded = await repository.getCategory('seed-food-drink');
      expect(
        seeded.getRight().toNullable()!.name,
        anyOf('Comida y bebida', 'Food & drink'),
      );
    });

    test(
        'propaga NetworkFailure sin escribir nada localmente cuando el '
        'catálogo remoto falla', () async {
      when(() => remoteSeeds.fetchCatalog()).thenThrow(
        const CategorySeedsFetchException('sin conexión'),
      );

      final seedResult = await repository.seedDefaultCategories();

      expect(seedResult.getLeft().toNullable(), isA<NetworkFailure>());
      expect(
        (await repository.hasAnyCategory()).getRight().toNullable(),
        isFalse,
      );
    });
  });
}
