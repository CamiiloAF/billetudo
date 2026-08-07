import 'package:billetudo/core/error/result.dart';
import 'package:billetudo/features/budgets/domain/entities/budget.dart';
import 'package:billetudo/features/budgets/domain/entities/budget_draft.dart';
import 'package:billetudo/features/budgets/domain/services/budget_category_scope_resolver.dart';
import 'package:billetudo/features/budgets/domain/usecases/count_active_budgets.dart';
import 'package:billetudo/features/budgets/domain/usecases/create_budget.dart';
import 'package:billetudo/features/budgets/domain/usecases/get_budget_by_id.dart';
import 'package:billetudo/features/budgets/domain/usecases/update_budget.dart';
import 'package:billetudo/features/budgets/presentation/cubit/budget_form_cubit.dart';
import 'package:billetudo/features/budgets/presentation/cubit/budget_form_state.dart';
import 'package:billetudo/features/categories/domain/entities/category.dart';
import 'package:billetudo/features/categories/domain/entities/category_node.dart';
import 'package:billetudo/features/categories/domain/usecases/watch_categories.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockCreateBudget extends Mock implements CreateBudget {}

class MockUpdateBudget extends Mock implements UpdateBudget {}

class MockGetBudgetById extends Mock implements GetBudgetById {}

class MockWatchCategories extends Mock implements WatchCategories {}

class MockCountActiveBudgets extends Mock implements CountActiveBudgets {}

/// Minitutorial at the "second active budget" moment
/// (`TutorialKey.budgetFeaturedChoice`,
/// `design-system/billetudo/pages/presupuestos.md` "Discoverability"): the
/// first budget is already auto-featured by `CreateBudget`, so no ambiguity
/// exists until a *second* one is created — that is the one moment the "¿cuál
/// se destaca?" minitutorial should fire. It is queried only right after a
/// successful *creation*, never an edit.
void main() {
  late MockCreateBudget createBudget;
  late MockUpdateBudget updateBudget;
  late MockGetBudgetById getBudgetById;
  late MockCountActiveBudgets countActiveBudgets;

  Budget budget({String id = 'b1'}) => Budget(
        id: id,
        name: 'Mercado',
        amountMinor: 500000,
        currency: 'COP',
        period: BudgetPeriod.monthly,
        startDate: DateTime(2026, 7, 21),
        recurring: true,
        rollover: false,
        createdAt: DateTime(2026, 7, 21),
        updatedAt: 0,
      );

  BudgetFormCubit build() {
    createBudget = MockCreateBudget();
    updateBudget = MockUpdateBudget();
    getBudgetById = MockGetBudgetById();
    countActiveBudgets = MockCountActiveBudgets();
    final watchCategories = MockWatchCategories();
    when(() => watchCategories(any())).thenAnswer(
      (_) => Stream<Result<List<CategoryNode>>>.value(
        const Right(<CategoryNode>[]),
      ),
    );
    return BudgetFormCubit(
      createBudget,
      updateBudget,
      getBudgetById,
      watchCategories,
      const BudgetCategoryScopeResolver(),
      countActiveBudgets,
    );
  }

  setUpAll(() => registerFallbackValue(CategoryKind.expense));
  setUpAll(() => registerFallbackValue(
        BudgetDraft(
          name: 'x',
          amountMinor: 1,
          currency: 'COP',
          period: BudgetPeriod.monthly,
          startDate: DateTime(2026),
          recurring: true,
        ),
      ));

  blocTest<BudgetFormCubit, BudgetFormState>(
    'creating a budget that becomes the second active one sets '
    'showFeaturedChoiceTutorial to true',
    build: () {
      final cubit = build();
      when(() => createBudget(any()))
          .thenAnswer((_) async => Right(budget()));
      when(() => countActiveBudgets())
          .thenAnswer((_) async => const Right(2));
      return cubit;
    },
    seed: () => BudgetFormState(
      status: BudgetFormStatus.ready,
      name: 'Mercado',
      amountMinor: 500000,
      startDate: DateTime(2026, 7, 21),
    ),
    act: (cubit) => cubit.submit(),
    verify: (cubit) {
      expect(cubit.state.showFeaturedChoiceTutorial, isTrue);
      expect(cubit.state.savedId, 'b1');
    },
  );

  blocTest<BudgetFormCubit, BudgetFormState>(
    'creating the first active budget (count == 1) never sets '
    'showFeaturedChoiceTutorial',
    build: () {
      final cubit = build();
      when(() => createBudget(any()))
          .thenAnswer((_) async => Right(budget()));
      when(() => countActiveBudgets())
          .thenAnswer((_) async => const Right(1));
      return cubit;
    },
    seed: () => BudgetFormState(
      status: BudgetFormStatus.ready,
      name: 'Mercado',
      amountMinor: 500000,
      startDate: DateTime(2026, 7, 21),
    ),
    act: (cubit) => cubit.submit(),
    verify: (cubit) {
      expect(cubit.state.showFeaturedChoiceTutorial, isFalse);
    },
  );

  blocTest<BudgetFormCubit, BudgetFormState>(
    'editing an existing budget never sets showFeaturedChoiceTutorial, even '
    'if it happens to be the second active one — and never even queries the '
    'count',
    build: () {
      final cubit = build();
      when(() => updateBudget(any()))
          .thenAnswer((_) async => Right(budget(id: 'b1')));
      when(() => countActiveBudgets())
          .thenAnswer((_) async => const Right(2));
      return cubit;
    },
    seed: () => BudgetFormState(
      status: BudgetFormStatus.ready,
      id: 'b1',
      name: 'Mercado',
      amountMinor: 500000,
      startDate: DateTime(2026, 7, 21),
    ),
    act: (cubit) => cubit.submit(),
    verify: (cubit) {
      expect(cubit.state.showFeaturedChoiceTutorial, isFalse);
      verifyNever(() => countActiveBudgets());
    },
  );

  blocTest<BudgetFormCubit, BudgetFormState>(
    'a failed count on the second creation is treated as "not the second" — '
    'save still succeeds but no tutorial fires',
    build: () {
      final cubit = build();
      when(() => createBudget(any()))
          .thenAnswer((_) async => Right(budget()));
      when(() => countActiveBudgets()).thenAnswer(
        (_) async => const Left(DatabaseFailure('count failed')),
      );
      return cubit;
    },
    seed: () => BudgetFormState(
      status: BudgetFormStatus.ready,
      name: 'Mercado',
      amountMinor: 500000,
      startDate: DateTime(2026, 7, 21),
    ),
    act: (cubit) => cubit.submit(),
    verify: (cubit) {
      expect(cubit.state.showFeaturedChoiceTutorial, isFalse);
      expect(cubit.state.savedId, 'b1');
    },
  );
}
