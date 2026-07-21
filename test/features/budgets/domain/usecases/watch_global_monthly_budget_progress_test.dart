import 'package:billetudo/core/error/result.dart';
import 'package:billetudo/features/budgets/domain/entities/budget.dart'
    show BudgetPeriod;
import 'package:billetudo/features/budgets/domain/entities/budget_period_window.dart';
import 'package:billetudo/features/budgets/domain/entities/budget_progress.dart';
import 'package:billetudo/features/budgets/domain/entities/budget_scope.dart';
import 'package:billetudo/features/budgets/domain/entities/budget_with_progress.dart';
import 'package:billetudo/features/budgets/domain/usecases/watch_global_monthly_budget_progress.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../budget_fixtures.dart';
import 'budget_repository_mock.dart';

/// Home's hero (HU-03, `aOhoY`): the single active budget that is both
/// global (`BudgetScope.isGlobal`) and monthly (`BudgetPeriod.monthly`).
void main() {
  late MockBudgetRepository repository;
  final window = BudgetPeriodWindow(
    start: DateTime(2026, 7, 1),
    endExclusive: DateTime(2026, 8, 1),
    index: 0,
    status: BudgetWindowStatus.current,
    hasPrevious: false,
    hasNext: true,
  );
  const progress = BudgetProgress(
    amountMinor: 600000,
    spentMinor: 300000,
    daysLeft: 12,
  );

  setUp(() => repository = MockBudgetRepository());

  BudgetWithProgress entry({
    required String id,
    BudgetScope scope = const BudgetScope.empty(),
    BudgetPeriod period = BudgetPeriod.monthly,
    required DateTime createdAt,
  }) =>
      BudgetWithProgress(
        budget: buildBudget(
          id: id,
          period: period,
          startDate: DateTime(2026, 7, 1),
          createdAt: createdAt,
        ),
        scope: scope,
        window: window,
        progress: progress,
      );

  test('emits the global-monthly budget when it is the only one', () async {
    final target = entry(id: 'b1', createdAt: DateTime(2026, 6, 1));
    when(() => repository.watchActiveBudgets()).thenAnswer(
      (_) => Stream<Result<List<BudgetWithProgress>>>.value(Right([target])),
    );

    final result =
        await WatchGlobalMonthlyBudgetProgress(repository).call().first;

    expect(result.getRight().toNullable(), target);
  });

  test('ignores budgets scoped to an account (not global)', () async {
    final scoped = entry(
      id: 'b-account',
      scope: const BudgetScope(
        accounts: [BudgetScopeRef(id: 'acc-1', referentAlive: true)],
      ),
      createdAt: DateTime(2026, 6, 1),
    );
    when(() => repository.watchActiveBudgets()).thenAnswer(
      (_) => Stream<Result<List<BudgetWithProgress>>>.value(Right([scoped])),
    );

    final result =
        await WatchGlobalMonthlyBudgetProgress(repository).call().first;

    expect(result.getRight().toNullable(), isNull);
  });

  test('ignores budgets scoped to a category (not global)', () async {
    final scoped = entry(
      id: 'b-category',
      scope: const BudgetScope(
        categories: [BudgetScopeRef(id: 'cat-1', referentAlive: true)],
      ),
      createdAt: DateTime(2026, 6, 1),
    );
    when(() => repository.watchActiveBudgets()).thenAnswer(
      (_) => Stream<Result<List<BudgetWithProgress>>>.value(Right([scoped])),
    );

    final result =
        await WatchGlobalMonthlyBudgetProgress(repository).call().first;

    expect(result.getRight().toNullable(), isNull);
  });

  test('ignores global budgets on a non-monthly period', () async {
    final weekly = entry(
      id: 'b-weekly',
      period: BudgetPeriod.weekly,
      createdAt: DateTime(2026, 6, 1),
    );
    when(() => repository.watchActiveBudgets()).thenAnswer(
      (_) => Stream<Result<List<BudgetWithProgress>>>.value(Right([weekly])),
    );

    final result =
        await WatchGlobalMonthlyBudgetProgress(repository).call().first;

    expect(result.getRight().toNullable(), isNull);
  });

  test('breaks ties by the most recently created qualifying budget',
      () async {
    final older = entry(id: 'older', createdAt: DateTime(2026, 1, 1));
    final newer = entry(id: 'newer', createdAt: DateTime(2026, 6, 15));
    final middle = entry(id: 'middle', createdAt: DateTime(2026, 3, 1));
    when(() => repository.watchActiveBudgets()).thenAnswer(
      (_) => Stream<Result<List<BudgetWithProgress>>>.value(
        Right([older, newer, middle]),
      ),
    );

    final result =
        await WatchGlobalMonthlyBudgetProgress(repository).call().first;

    expect(result.getRight().toNullable()?.budget.id, 'newer');
  });

  test('emits null when no active budget qualifies', () async {
    when(() => repository.watchActiveBudgets()).thenAnswer(
      (_) => Stream<Result<List<BudgetWithProgress>>>.value(
        const Right(<BudgetWithProgress>[]),
      ),
    );

    final result =
        await WatchGlobalMonthlyBudgetProgress(repository).call().first;

    expect(result.getRight().toNullable(), isNull);
  });

  test('propagates a repository failure as Left', () async {
    const failure = DatabaseFailure('boom');
    when(() => repository.watchActiveBudgets()).thenAnswer(
      (_) => Stream<Result<List<BudgetWithProgress>>>.value(
        const Left(failure),
      ),
    );

    final result =
        await WatchGlobalMonthlyBudgetProgress(repository).call().first;

    expect(result.getLeft().toNullable(), failure);
  });
}
