import 'package:billetudo/core/database/app_database.dart';
import 'package:billetudo/features/categories/data/datasources/categories_local_datasource.dart';
import 'package:billetudo/features/categories/data/models/category_seed_entry.dart';
import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase db;
  late CategoriesLocalDatasource datasource;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    datasource = CategoriesLocalDatasource(db);
  });

  tearDown(() async => db.close());

  Future<Category> insertCategory({
    required String name,
    CategoryKind kind = CategoryKind.expense,
    String? parentId,
    int sortOrder = 0,
    DateTime? deletedAt,
    DateTime? tombstonedAt,
  }) =>
      db.into(db.categories).insertReturning(
            CategoriesCompanion.insert(
              name: name,
              kind: kind,
              parentId: Value(parentId),
              sortOrder: Value(sortOrder),
              deletedAt: Value(deletedAt),
              tombstonedAt: Value(tombstonedAt),
            ),
          );

  group('watchCategories', () {
    test('excluye tombstoned y deleted, ordena por sortOrder', () async {
      final b = await insertCategory(name: 'B', sortOrder: 1);
      final a = await insertCategory(name: 'A');
      await insertCategory(
        name: 'Borrada',
        deletedAt: DateTime(2026, 7),
      );
      await insertCategory(
        name: 'Tombstoned',
        tombstonedAt: DateTime(2026, 7),
      );

      final result =
          await datasource.watchCategories(CategoryKind.expense).first;

      expect(result.map((c) => c.id), [a.id, b.id]);
    });

    test('no mezcla kinds', () async {
      await insertCategory(name: 'Salario', kind: CategoryKind.income);
      final expense = await insertCategory(name: 'Comida');

      final result =
          await datasource.watchCategories(CategoryKind.expense).first;

      expect(result.map((c) => c.id), [expense.id]);
    });
  });

  group('watchParentCandidates', () {
    test('solo trae raíces del kind pedido', () async {
      final root = await insertCategory(name: 'Comida');
      await insertCategory(name: 'Mercado', parentId: root.id);
      await insertCategory(name: 'Salario', kind: CategoryKind.income);

      final result =
          await datasource.watchParentCandidates(CategoryKind.expense).first;

      expect(result.map((c) => c.id), [root.id]);
    });

    test('excludingId omite la propia raíz', () async {
      final root1 = await insertCategory(name: 'Comida');
      final root2 = await insertCategory(name: 'Transporte', sortOrder: 1);

      final result = await datasource
          .watchParentCandidates(CategoryKind.expense, excludingId: root1.id)
          .first;

      expect(result.map((c) => c.id), [root2.id]);
    });
  });

  group('nextSortOrder', () {
    test('0 cuando no hay categorías en ese scope', () async {
      final next = await datasource.nextSortOrder(CategoryKind.expense);
      expect(next, 0);
    });

    test('siguiente entre raíces cuando parentId es null', () async {
      await insertCategory(name: 'A');
      await insertCategory(name: 'B', sortOrder: 1);

      final next = await datasource.nextSortOrder(CategoryKind.expense);

      expect(next, 2);
    });

    test('siguiente entre hermanas cuando parentId no es null', () async {
      final root = await insertCategory(name: 'Comida');
      await insertCategory(name: 'Mercado', parentId: root.id);

      final next = await datasource.nextSortOrder(
        CategoryKind.expense,
        parentId: root.id,
      );

      expect(next, 1);
      // Y no se ve afectado por el sortOrder de las raíces.
      final nextRoot = await datasource.nextSortOrder(CategoryKind.expense);
      expect(nextRoot, 1);
    });
  });

  group('countActiveSubcategories / countActiveTransactions', () {
    test('cuenta solo subcategorías activas', () async {
      final root = await insertCategory(name: 'Comida');
      await insertCategory(name: 'Mercado', parentId: root.id);
      await insertCategory(
        name: 'Borrada',
        parentId: root.id,
        deletedAt: DateTime(2026, 7),
      );

      final count = await datasource.countActiveSubcategories(root.id);

      expect(count, 1);
    });

    test('cuenta solo transacciones activas', () async {
      final root = await insertCategory(name: 'Comida');
      await db.into(db.transactions).insert(
            TransactionsCompanion.insert(
              accountId: await _insertAccount(db),
              categoryId: Value(root.id),
              amountMinor: 1000,
              currency: 'COP',
              type: EntryType.expense,
              date: DateTime(2026, 7, 10),
            ),
          );
      await db.into(db.transactions).insert(
            TransactionsCompanion.insert(
              accountId: await _insertAccount(db),
              categoryId: Value(root.id),
              amountMinor: 1000,
              currency: 'COP',
              type: EntryType.expense,
              date: DateTime(2026, 7, 10),
              deletedAt: Value(DateTime(2026, 7, 12)),
            ),
          );

      final count = await datasource.countActiveTransactions(root.id);

      expect(count, 1);
    });
  });

  group(
      'reassignSubcategories / reassignTransactions / '
      'clearTransactionCategory', () {
    test('mueve todas las subcategorías activas a otra raíz', () async {
      final root1 = await insertCategory(name: 'Comida');
      final root2 = await insertCategory(name: 'Restaurantes', sortOrder: 1);
      final sub = await insertCategory(name: 'Mercado', parentId: root1.id);

      await datasource.reassignSubcategories(
        root1.id,
        root2.id,
        DateTime(2026, 7, 15),
      );

      final row = await datasource.getCategory(sub.id);
      expect(row!.parentId, root2.id);
      expect(row.updatedAt, DateTime(2026, 7, 15).millisecondsSinceEpoch);
    });

    test('reasignar transacciones actualiza categoryId y updatedAt', () async {
      final root1 = await insertCategory(name: 'Comida');
      final root2 = await insertCategory(name: 'Restaurantes', sortOrder: 1);
      final accountId = await _insertAccount(db);
      await db.into(db.transactions).insert(
            TransactionsCompanion.insert(
              accountId: accountId,
              categoryId: Value(root1.id),
              amountMinor: 1000,
              currency: 'COP',
              type: EntryType.expense,
              date: DateTime(2026, 7, 10),
            ),
          );

      await datasource.reassignTransactions(
        root1.id,
        root2.id,
        DateTime(2026, 7, 15),
      );

      final tx = await db.select(db.transactions).getSingle();
      expect(tx.categoryId, root2.id);
      expect(tx.updatedAt, DateTime(2026, 7, 15).millisecondsSinceEpoch);
    });

    test('dejar sin categoría pone categoryId en null', () async {
      final root = await insertCategory(name: 'Comida');
      final accountId = await _insertAccount(db);
      await db.into(db.transactions).insert(
            TransactionsCompanion.insert(
              accountId: accountId,
              categoryId: Value(root.id),
              amountMinor: 1000,
              currency: 'COP',
              type: EntryType.expense,
              date: DateTime(2026, 7, 10),
            ),
          );

      await datasource.clearTransactionCategory(
        root.id,
        DateTime(2026, 7, 15),
      );

      final tx = await db.select(db.transactions).getSingle();
      expect(tx.categoryId, isNull);
    });
  });

  group('softDeleteCategory / cascadeDeleteCategory / restoreCategory', () {
    test('softDeleteCategory usa deletedAt, nunca tombstonedAt', () async {
      final category = await insertCategory(name: 'Comida');

      final row = await datasource.softDeleteCategory(
        category.id,
        DateTime(2026, 7, 15),
      );

      expect(row!.deletedAt, isNotNull);
      expect(row.tombstonedAt, isNull);
    });

    test('cascadeDeleteCategory borra la raíz y sus subcategorías activas',
        () async {
      final root = await insertCategory(name: 'Vehículo');
      final sub1 = await insertCategory(name: 'Combustible', parentId: root.id);
      final sub2 = await insertCategory(
          name: 'Mantenimiento', parentId: root.id, sortOrder: 1);

      await datasource.cascadeDeleteCategory(root.id, DateTime(2026, 7, 15));

      final all = await db.select(db.categories).get();
      final rootRow = all.firstWhere((c) => c.id == root.id);
      final sub1Row = all.firstWhere((c) => c.id == sub1.id);
      final sub2Row = all.firstWhere((c) => c.id == sub2.id);
      expect(rootRow.deletedAt, isNotNull);
      expect(sub1Row.deletedAt, isNotNull);
      expect(sub2Row.deletedAt, isNotNull);
    });

    test('restoreCategory limpia deletedAt sin tocar tombstonedAt', () async {
      final category = await insertCategory(
        name: 'Comida',
        deletedAt: DateTime(2026, 7),
      );

      final row =
          await datasource.restoreCategory(category.id, DateTime(2026, 7, 15));

      expect(row!.deletedAt, isNull);
      expect(row.tombstonedAt, isNull);
    });

    test('restoreCategory no exige que el padre siga vivo', () async {
      final root = await insertCategory(
        name: 'Comida',
        deletedAt: DateTime(2026, 7),
      );
      final sub = await insertCategory(
        name: 'Mercado',
        parentId: root.id,
        deletedAt: DateTime(2026, 7),
      );

      final row =
          await datasource.restoreCategory(sub.id, DateTime(2026, 7, 15));

      expect(row!.deletedAt, isNull);
      expect(row.parentId, root.id);
    });
  });

  group('reorderCategories', () {
    test('reordena de forma transaccional y contigua', () async {
      final a = await insertCategory(name: 'A');
      final b = await insertCategory(name: 'B', sortOrder: 1);
      final c = await insertCategory(name: 'C', sortOrder: 2);

      await datasource.reorderCategories(
        [b.id, c.id, a.id],
        DateTime(2026, 7, 15),
      );

      final rowB = await datasource.getCategory(b.id);
      final rowC = await datasource.getCategory(c.id);
      final rowA = await datasource.getCategory(a.id);
      expect(rowB!.sortOrder, 0);
      expect(rowC!.sortOrder, 1);
      expect(rowA!.sortOrder, 2);
    });
  });

  group('countActiveCategories / seedDefaultCategories', () {
    // Small fixture standing in for the real `category_seeds` catalog
    // (docs/requirements/05-auth-sync.md, decision #12): 2 expense roots (one
    // with subcategories) + 1 income root, deliberately listed with a
    // subcategory *before* its root to prove the datasource reorders for the
    // `parentId` FK instead of relying on catalog row order.
    final catalog = [
      const CategorySeedEntry(
        id: 'seed-food-market',
        kind: CategoryKind.expense,
        parentId: 'seed-food-drink',
        nameEs: 'Mercado',
        nameEn: 'Groceries',
        icon: null,
        color: null,
        sortOrder: 0,
      ),
      const CategorySeedEntry(
        id: 'seed-food-drink',
        kind: CategoryKind.expense,
        parentId: null,
        nameEs: 'Comida y bebida',
        nameEn: 'Food & drink',
        icon: 'utensils',
        color: 'mint',
        sortOrder: 0,
      ),
      const CategorySeedEntry(
        id: 'seed-transport',
        kind: CategoryKind.expense,
        parentId: null,
        nameEs: 'Transporte',
        nameEn: 'Transport',
        icon: 'bus',
        color: 'sky',
        sortOrder: 1,
      ),
      const CategorySeedEntry(
        id: 'seed-salary',
        kind: CategoryKind.income,
        parentId: null,
        nameEs: 'Salario',
        nameEn: 'Salary',
        icon: 'banknote',
        color: 'mint',
        sortOrder: 0,
      ),
    ];

    test('0 sin categorías, > 0 tras crear una', () async {
      expect(await datasource.countActiveCategories(), 0);

      await insertCategory(name: 'Comida');

      expect(await datasource.countActiveCategories(), greaterThan(0));
    });

    test(
        'inserta el catálogo con los ids estables del seed y el idioma '
        'pedido, ordenando raíces antes que subcategorías', () async {
      await datasource.seedDefaultCategories(
        catalog,
        DateTime(2026, 7, 15),
        'es',
      );

      final all = await db.select(db.categories).get();
      expect(all, hasLength(4));

      final food =
          all.singleWhere((c) => c.id == 'seed-food-drink');
      expect(food.name, 'Comida y bebida');
      expect(food.parentId, isNull);
      expect(food.kind, CategoryKind.expense);

      final market = all.singleWhere((c) => c.id == 'seed-food-market');
      expect(market.name, 'Mercado');
      expect(market.parentId, 'seed-food-drink');

      final salary = all.singleWhere((c) => c.id == 'seed-salary');
      expect(salary.kind, CategoryKind.income);
    });

    test('usa name_en cuando se le pide el idioma en', () async {
      await datasource.seedDefaultCategories(
        catalog,
        DateTime(2026, 7, 15),
        'en',
      );

      final food = await datasource.getCategory('seed-food-drink');
      expect(food!.name, 'Food & drink');
    });

    test(
        'llamarlo dos veces con el mismo catálogo falla por choque de id '
        '(la idempotencia es responsabilidad del use case, no de este '
        'datasource)', () async {
      await datasource.seedDefaultCategories(
        catalog,
        DateTime(2026, 7, 15),
        'es',
      );

      expect(
        () => datasource.seedDefaultCategories(
          catalog,
          DateTime(2026, 7, 15),
          'es',
        ),
        throwsA(anything),
      );
    });
  });

  group('mostUsedCategories', () {
    Future<void> addTransaction(String accountId, String categoryId) =>
        db.into(db.transactions).insert(
              TransactionsCompanion.insert(
                accountId: accountId,
                categoryId: Value(categoryId),
                amountMinor: 1000,
                currency: 'COP',
                type: EntryType.expense,
                date: DateTime(2026, 7, 10),
              ),
            );

    test('ordena por conteo de transacciones activas, descendente', () async {
      final accountId = await _insertAccount(db);
      final comida = await insertCategory(name: 'Comida');
      final transporte = await insertCategory(name: 'Transporte', sortOrder: 1);
      final ocio = await insertCategory(name: 'Ocio', sortOrder: 2);

      // Transporte: 2 usos, Comida: 1, Ocio: 0.
      await addTransaction(accountId, transporte.id);
      await addTransaction(accountId, transporte.id);
      await addTransaction(accountId, comida.id);

      final result =
          await datasource.mostUsedCategories(CategoryKind.expense, 3);

      expect(
        result.map((c) => c.id),
        [transporte.id, comida.id, ocio.id],
      );
    });

    test('sin historial, cae en las primeras raíces por sortOrder', () async {
      final comida = await insertCategory(name: 'Comida');
      final transporte = await insertCategory(name: 'Transporte', sortOrder: 1);
      // Una subcategoría no debe adelantar a las raíces en el fallback.
      await insertCategory(name: 'Mercado', parentId: comida.id);

      final result =
          await datasource.mostUsedCategories(CategoryKind.expense, 2);

      expect(result.map((c) => c.id), [comida.id, transporte.id]);
    });

    test('respeta el limit y excluye borradas', () async {
      final accountId = await _insertAccount(db);
      final comida = await insertCategory(name: 'Comida');
      await insertCategory(name: 'Transporte', sortOrder: 1);
      await insertCategory(
        name: 'Borrada',
        sortOrder: 2,
        deletedAt: DateTime(2026, 7),
      );
      await addTransaction(accountId, comida.id);

      final result =
          await datasource.mostUsedCategories(CategoryKind.expense, 1);

      expect(result.map((c) => c.id), [comida.id]);
    });
  });

  group('countReferencingBudgets', () {
    Future<String> insertBudget({
      String name = 'Presupuesto',
      DateTime? archivedAt,
      DateTime? deletedAt,
      DateTime? tombstonedAt,
    }) =>
        db
            .into(db.budgets)
            .insertReturning(
              BudgetsCompanion.insert(
                name: name,
                amountMinor: 100000,
                currency: 'COP',
                period: BudgetPeriod.monthly,
                startDate: DateTime(2026, 1, 1),
                archivedAt: Value(archivedAt),
                deletedAt: Value(deletedAt),
                tombstonedAt: Value(tombstonedAt),
              ),
            )
            .then((row) => row.id);

    Future<void> insertBudgetCategory(
      String budgetId,
      String categoryId, {
      DateTime? deletedAt,
      DateTime? tombstonedAt,
    }) =>
        db.into(db.budgetCategories).insert(
              BudgetCategoriesCompanion.insert(
                budgetId: budgetId,
                categoryId: categoryId,
                deletedAt: Value(deletedAt),
                tombstonedAt: Value(tombstonedAt),
              ),
            );

    test('0 cuando ningún presupuesto referencia la categoría', () async {
      final category = await insertCategory(name: 'Comida');

      final count = await datasource.countReferencingBudgets(category.id);

      expect(count, 0);
    });

    test('cuenta un presupuesto activo cuyo alcance referencia la categoría',
        () async {
      final category = await insertCategory(name: 'Comida');
      final budgetId = await insertBudget();
      await insertBudgetCategory(budgetId, category.id);

      final count = await datasource.countReferencingBudgets(category.id);

      expect(count, 1);
    });

    test('NO cuenta un presupuesto cerrado (archivedAt)', () async {
      final category = await insertCategory(name: 'Comida');
      final budgetId = await insertBudget(archivedAt: DateTime(2026, 7, 15));
      await insertBudgetCategory(budgetId, category.id);

      final count = await datasource.countReferencingBudgets(category.id);

      expect(count, 0);
    });

    test('NO cuenta un presupuesto borrado (deletedAt)', () async {
      final category = await insertCategory(name: 'Comida');
      final budgetId = await insertBudget(deletedAt: DateTime(2026, 7, 15));
      await insertBudgetCategory(budgetId, category.id);

      final count = await datasource.countReferencingBudgets(category.id);

      expect(count, 0);
    });

    test('NO cuenta un presupuesto tombstoned', () async {
      final category = await insertCategory(name: 'Comida');
      final budgetId = await insertBudget(tombstonedAt: DateTime(2026, 7, 15));
      await insertBudgetCategory(budgetId, category.id);

      final count = await datasource.countReferencingBudgets(category.id);

      expect(count, 0);
    });

    test('NO cuenta una fila de alcance borrada aunque el presupuesto activo',
        () async {
      final category = await insertCategory(name: 'Comida');
      final budgetId = await insertBudget();
      await insertBudgetCategory(
        budgetId,
        category.id,
        deletedAt: DateTime(2026, 7, 15),
      );

      final count = await datasource.countReferencingBudgets(category.id);

      expect(count, 0);
    });

    test(
        'NO cuenta una fila de alcance tombstoned aunque el presupuesto '
        'activo', () async {
      final category = await insertCategory(name: 'Comida');
      final budgetId = await insertBudget();
      await insertBudgetCategory(
        budgetId,
        category.id,
        tombstonedAt: DateTime(2026, 7, 15),
      );

      final count = await datasource.countReferencingBudgets(category.id);

      expect(count, 0);
    });

    test('ignora presupuestos que apuntan a otra categoría', () async {
      final category = await insertCategory(name: 'Comida');
      final otherCategory = await insertCategory(name: 'Transporte');
      final budgetId = await insertBudget();
      await insertBudgetCategory(budgetId, otherCategory.id);

      final count = await datasource.countReferencingBudgets(category.id);

      expect(count, 0);
    });
  });
}

Future<String> _insertAccount(AppDatabase db) => db
    .into(db.accounts)
    .insertReturning(
      AccountsCompanion.insert(
        name: 'Cuenta',
        type: AccountType.bank,
        currency: 'COP',
      ),
    )
    .then((row) => row.id);
