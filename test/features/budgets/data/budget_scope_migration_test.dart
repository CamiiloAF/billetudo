import 'package:billetudo/core/database/app_database.dart' hide BudgetPeriod;
import 'package:billetudo/features/budgets/data/datasources/budgets_local_datasource.dart';
import 'package:billetudo/features/budgets/data/repositories/budget_repository_impl.dart';
import 'package:billetudo/features/budgets/domain/entities/budget.dart'
    show BudgetPeriod;
import 'package:billetudo/features/budgets/domain/entities/budget_draft.dart';
import 'package:billetudo/features/budgets/domain/services/budget_category_scope_resolver.dart';
import 'package:billetudo/features/budgets/domain/services/budget_progress_calculator.dart';
import 'package:billetudo/features/budgets/domain/services/zero_based_summary_calculator.dart';
import 'package:billetudo/features/scheduled_payments/domain/usecases/project_upcoming_occurrences.dart';
import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

/// Fix #14 migration: budgets saved with a materialized category scope ("Todas"
/// as every id, or a root plus all its children) are reconciled into the
/// canonical form ("Todas" -> empty/global, a whole root -> just the root id) so
/// categories created later are counted. Runs against a real (in-memory) Drift
/// schema and must be idempotent.
void main() {
  late AppDatabase database;
  late BudgetsLocalDatasource datasource;
  late BudgetRepositoryImpl repository;

  setUp(() {
    database = AppDatabase(NativeDatabase.memory());
    datasource = BudgetsLocalDatasource(database);
    repository = BudgetRepositoryImpl(
      datasource,
      const BudgetProgressCalculator(),
      const ZeroBasedSummaryCalculator(),
      const ProjectUpcomingOccurrences(),
      const BudgetCategoryScopeResolver(),
    );
  });

  tearDown(() async => database.close());

  Future<Category> createCategory(
    String name, {
    required CategoryKind kind,
    String? parentId,
  }) =>
      database.into(database.categories).insertReturning(
            CategoriesCompanion.insert(
              name: name,
              kind: kind,
              parentId: Value(parentId),
            ),
          );

  Future<String> createBudget() async {
    final result = await repository.createBudget(
      BudgetDraft(
        name: 'Mercado',
        amountMinor: 100000,
        currency: 'COP',
        period: BudgetPeriod.monthly,
        startDate: DateTime(2026, 7, 1),
        recurring: true,
      ),
    );
    return result.getRight().toNullable()!.id;
  }

  Future<void> materializeScope(String budgetId, Set<String> categoryIds) =>
      datasource.reconcileScope(
        budgetId,
        accountIds: const {},
        categoryIds: categoryIds,
        now: DateTime(2026, 7, 1),
      );

  /// Seeds two roots (food: 2 children, bills: 1 child) and returns their ids.
  Future<({List<String> all, String food, List<String> foodChildren})>
      seedTree() async {
    final food = await createCategory('Comida', kind: CategoryKind.expense);
    final groceries = await createCategory(
      'Mercado',
      kind: CategoryKind.expense,
      parentId: food.id,
    );
    final dining = await createCategory(
      'Restaurantes',
      kind: CategoryKind.expense,
      parentId: food.id,
    );
    final bills = await createCategory('Servicios', kind: CategoryKind.expense);
    final power = await createCategory(
      'Luz',
      kind: CategoryKind.expense,
      parentId: bills.id,
    );
    return (
      all: [food.id, groceries.id, dining.id, bills.id, power.id],
      food: food.id,
      foodChildren: [groceries.id, dining.id],
    );
  }

  test('a scope materialized over every live category becomes global (empty)',
      () async {
    final tree = await seedTree();
    final budgetId = await createBudget();
    await materializeScope(budgetId, tree.all.toSet());

    final result = await repository.reconcileMaterializedCategoryScopes();
    expect(result.isRight(), isTrue);

    expect(await datasource.categoryScopeOf(budgetId), isEmpty);
  });

  test('a scope materialized over a whole root collapses to just the root',
      () async {
    final tree = await seedTree();
    final budgetId = await createBudget();
    await materializeScope(
      budgetId,
      {tree.food, ...tree.foodChildren},
    );

    await repository.reconcileMaterializedCategoryScopes();

    expect(await datasource.categoryScopeOf(budgetId), [tree.food]);
  });

  test('a genuinely partial pick is left untouched', () async {
    final tree = await seedTree();
    final budgetId = await createBudget();
    final partial = {tree.food, tree.foodChildren.first};
    await materializeScope(budgetId, partial);

    await repository.reconcileMaterializedCategoryScopes();

    expect(
      (await datasource.categoryScopeOf(budgetId)).toSet(),
      partial,
    );
  });

  test('an already-global budget is left global', () async {
    await seedTree();
    final budgetId = await createBudget();
    // No scope rows at all = global.

    await repository.reconcileMaterializedCategoryScopes();

    expect(await datasource.categoryScopeOf(budgetId), isEmpty);
  });

  test('a new category added after a "Todas" budget was global is counted',
      () async {
    final tree = await seedTree();
    final budgetId = await createBudget();
    await materializeScope(budgetId, tree.all.toSet());
    await repository.reconcileMaterializedCategoryScopes();

    // A 6th category appears later; a global scope has no rows to freeze, so it
    // is implicitly covered — the scope stays empty.
    await createCategory('Nueva', kind: CategoryKind.expense);
    await repository.reconcileMaterializedCategoryScopes();

    expect(await datasource.categoryScopeOf(budgetId), isEmpty);
  });

  test('running twice is idempotent for every case', () async {
    final tree = await seedTree();
    final allId = await createBudget();
    await materializeScope(allId, tree.all.toSet());
    final rootId = await createBudget();
    await materializeScope(rootId, {tree.food, ...tree.foodChildren});

    await repository.reconcileMaterializedCategoryScopes();
    final allAfterFirst = await datasource.categoryScopeOf(allId);
    final rootAfterFirst = await datasource.categoryScopeOf(rootId);

    await repository.reconcileMaterializedCategoryScopes();

    expect(await datasource.categoryScopeOf(allId), allAfterFirst);
    expect(await datasource.categoryScopeOf(rootId), rootAfterFirst);
    expect(allAfterFirst, isEmpty);
    expect(rootAfterFirst, [tree.food]);
  });
}
