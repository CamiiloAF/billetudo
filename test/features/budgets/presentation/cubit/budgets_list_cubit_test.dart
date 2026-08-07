import 'package:billetudo/core/error/result.dart';
import 'package:billetudo/features/budgets/domain/entities/budget.dart';
import 'package:billetudo/features/budgets/domain/entities/budget_period_window.dart';
import 'package:billetudo/features/budgets/domain/entities/budget_progress.dart';
import 'package:billetudo/features/budgets/domain/entities/budget_scope.dart';
import 'package:billetudo/features/budgets/domain/entities/budget_with_progress.dart';
import 'package:billetudo/features/budgets/domain/usecases/get_active_budgets.dart';
import 'package:billetudo/features/budgets/domain/usecases/reconcile_budget_scopes.dart';
import 'package:billetudo/features/budgets/domain/usecases/watch_featured_budget_progress.dart';
import 'package:billetudo/features/budgets/presentation/cubit/budgets_list_cubit.dart';
import 'package:billetudo/features/budgets/presentation/cubit/budgets_list_state.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockGetActiveBudgets extends Mock implements GetActiveBudgets {}

class MockReconcileBudgetScopes extends Mock
    implements ReconcileBudgetScopes {}

class MockWatchFeaturedBudgetProgress extends Mock
    implements WatchFeaturedBudgetProgress {}

/// Discoverability fix (`design-system/billetudo/pages/presupuestos.md`,
/// "Destacar presupuesto en Inicio"): `featuredBudgetId` on the list state
/// must mirror whatever `WatchFeaturedBudgetProgress`/`BudgetHeroSelector`
/// resolves — manual pick or automatic fallback — never a raw manual pick
/// read directly off `AppSettingsCubit`, which is exactly the bug that let
/// the list's star badge disagree with what the Home hero actually showed.
void main() {
  late MockGetActiveBudgets getActiveBudgets;
  late MockReconcileBudgetScopes reconcileBudgetScopes;
  late MockWatchFeaturedBudgetProgress watchFeaturedBudgetProgress;

  BudgetWithProgress budgetWith(String id) => BudgetWithProgress(
        budget: Budget(
          id: id,
          name: 'Budget $id',
          amountMinor: 600000,
          currency: 'COP',
          period: BudgetPeriod.monthly,
          startDate: DateTime(2026, 7, 1),
          recurring: true,
          rollover: false,
          createdAt: DateTime(2026, 7, 1),
          updatedAt: 0,
        ),
        scope: const BudgetScope.empty(),
        window: BudgetPeriodWindow(
          start: DateTime(2026, 7, 1),
          endExclusive: DateTime(2026, 8, 1),
          index: 0,
          status: BudgetWindowStatus.current,
          hasPrevious: false,
          hasNext: true,
        ),
        progress:
            const BudgetProgress(amountMinor: 600000, spentMinor: 0, daysLeft: 12),
      );

  BudgetsListCubit build() {
    getActiveBudgets = MockGetActiveBudgets();
    reconcileBudgetScopes = MockReconcileBudgetScopes();
    watchFeaturedBudgetProgress = MockWatchFeaturedBudgetProgress();
    when(() => reconcileBudgetScopes())
        .thenAnswer((_) async => const Right(unit));
    return BudgetsListCubit(
      getActiveBudgets,
      reconcileBudgetScopes,
      watchFeaturedBudgetProgress,
    );
  }

  blocTest<BudgetsListCubit, BudgetsListState>(
    'featuredBudgetId reflects WatchFeaturedBudgetProgress\'s manual pick, '
    'not a raw one',
    build: () {
      final cubit = build();
      final manual = budgetWith('manual-1');
      when(() => getActiveBudgets()).thenAnswer(
        (_) => Stream.value(Right([manual, budgetWith('other')])),
      );
      when(() => watchFeaturedBudgetProgress())
          .thenAnswer((_) => Stream.value(Right(manual)));
      return cubit;
    },
    act: (cubit) => cubit.start(),
    wait: const Duration(milliseconds: 10),
    verify: (cubit) {
      expect(cubit.state.featuredBudgetId, 'manual-1');
    },
  );

  blocTest<BudgetsListCubit, BudgetsListState>(
    'featuredBudgetId reflects the automatic fallback when there is no '
    'manual pick (BudgetHeroSelector resolves it, not raw AppSettings)',
    build: () {
      final cubit = build();
      final fallback = budgetWith('auto-fallback');
      when(() => getActiveBudgets())
          .thenAnswer((_) => Stream.value(Right([fallback])));
      when(() => watchFeaturedBudgetProgress())
          .thenAnswer((_) => Stream.value(Right(fallback)));
      return cubit;
    },
    act: (cubit) => cubit.start(),
    wait: const Duration(milliseconds: 10),
    verify: (cubit) {
      expect(cubit.state.featuredBudgetId, 'auto-fallback');
    },
  );

  blocTest<BudgetsListCubit, BudgetsListState>(
    'no active budget at all: featuredBudgetId stays null',
    build: () {
      final cubit = build();
      when(() => getActiveBudgets())
          .thenAnswer((_) => Stream.value(const Right([])));
      when(() => watchFeaturedBudgetProgress())
          .thenAnswer((_) => Stream.value(const Right(null)));
      return cubit;
    },
    act: (cubit) => cubit.start(),
    wait: const Duration(milliseconds: 10),
    verify: (cubit) {
      expect(cubit.state.featuredBudgetId, isNull);
    },
  );

  blocTest<BudgetsListCubit, BudgetsListState>(
    'a failure resolving the featured budget leaves featuredBudgetId as it '
    'was, never downgrading the whole list to a failure state',
    build: () {
      final cubit = build();
      final budget = budgetWith('b1');
      when(() => getActiveBudgets())
          .thenAnswer((_) => Stream.value(Right([budget])));
      when(() => watchFeaturedBudgetProgress()).thenAnswer(
        (_) => Stream.value(
          const Left(UnexpectedFailure('boom')),
        ),
      );
      return cubit;
    },
    act: (cubit) => cubit.start(),
    wait: const Duration(milliseconds: 10),
    verify: (cubit) {
      expect(cubit.state.featuredBudgetId, isNull);
      expect(cubit.state.status, BudgetsListStatus.ready);
    },
  );
}
