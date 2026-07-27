import 'package:billetudo/core/error/result.dart';
import 'package:billetudo/features/budgets/domain/services/budget_category_scope_resolver.dart';
import 'package:billetudo/features/budgets/domain/usecases/create_budget.dart';
import 'package:billetudo/features/budgets/domain/usecases/get_budget_by_id.dart';
import 'package:billetudo/features/budgets/domain/usecases/update_budget.dart';
import 'package:billetudo/features/budgets/presentation/cubit/budget_form_cubit.dart';
import 'package:billetudo/features/categories/domain/entities/category.dart';
import 'package:billetudo/features/categories/domain/entities/category_node.dart';
import 'package:billetudo/features/categories/domain/usecases/watch_categories.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockCreateBudget extends Mock implements CreateBudget {}

class MockUpdateBudget extends Mock implements UpdateBudget {}

class MockGetBudgetById extends Mock implements GetBudgetById {}

class MockWatchCategories extends Mock implements WatchCategories {}

/// Fix #14 at the form seam: the shared picker speaks materialized ids, but the
/// budget must store the canonical scope ("Todas" -> empty, a whole root -> its
/// id alone) so categories created later are counted.
void main() {
  Category cat(String id, {String? parentId}) => Category(
        id: id,
        name: id,
        kind: CategoryKind.expense,
        parentId: parentId,
        sortOrder: 0,
        createdAt: DateTime(2026),
        updatedAt: 0,
      );

  // Root `food` (2 children) + childless root `bills`.
  final expenseTree = [
    CategoryNode(
      root: cat('food'),
      subcategories: [
        cat('groceries', parentId: 'food'),
        cat('dining', parentId: 'food')
      ],
    ),
    CategoryNode(root: cat('bills')),
  ];
  const allIds = {'food', 'groceries', 'dining', 'bills'};

  late MockWatchCategories watchCategories;

  setUpAll(() => registerFallbackValue(CategoryKind.expense));

  BudgetFormCubit build() {
    watchCategories = MockWatchCategories();
    when(() => watchCategories(CategoryKind.expense)).thenAnswer(
      (_) => Stream.value(Right(expenseTree)),
    );
    when(() => watchCategories(CategoryKind.income)).thenAnswer(
      (_) => Stream.value(const Right(<CategoryNode>[])),
    );
    return BudgetFormCubit(
      MockCreateBudget(),
      MockUpdateBudget(),
      MockGetBudgetById(),
      watchCategories,
      const BudgetCategoryScopeResolver(),
    );
  }

  test('a fresh (global) budget seeds the picker with every id checked',
      () async {
    final cubit = build();
    await cubit.load(null);

    expect(await cubit.categoryScopeForPicker(), allIds);

    await cubit.close();
  });

  test('picking "Todas" (every id) stores the empty/global scope', () async {
    final cubit = build();
    await cubit.load(null);
    await cubit.categoryScopeForPicker(); // ensures the tree is loaded

    cubit.categoriesPicked(allIds.toSet());

    expect(cubit.state.categoryIds, isEmpty);
    await cubit.close();
  });

  test('picking a whole root stores just the root id', () async {
    final cubit = build();
    await cubit.load(null);
    await cubit.categoryScopeForPicker();

    cubit.categoriesPicked({'food', 'groceries', 'dining'});

    expect(cubit.state.categoryIds, {'food'});
    await cubit.close();
  });

  test('picking a lone subcategory keeps just that subcategory', () async {
    final cubit = build();
    await cubit.load(null);
    await cubit.categoryScopeForPicker();

    cubit.categoriesPicked({'dining'});

    expect(cubit.state.categoryIds, {'dining'});
    await cubit.close();
  });

  test('a root-only scope re-expands to the whole subtree for the picker',
      () async {
    final cubit = build();
    await cubit.load(null);
    await cubit.categoryScopeForPicker();
    cubit.categoriesPicked({'food', 'groceries', 'dining'});

    // Stored canonical ({food}); re-opening the picker shows the subtree.
    expect(
      await cubit.categoryScopeForPicker(),
      {'food', 'groceries', 'dining'},
    );
    await cubit.close();
  });
}
