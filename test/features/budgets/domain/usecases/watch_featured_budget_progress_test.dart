import 'dart:async';

import 'package:billetudo/core/error/result.dart';
import 'package:billetudo/features/budgets/domain/entities/budget.dart'
    show BudgetPeriod;
import 'package:billetudo/features/budgets/domain/entities/budget_period_window.dart';
import 'package:billetudo/features/budgets/domain/entities/budget_progress.dart';
import 'package:billetudo/features/budgets/domain/entities/budget_scope.dart';
import 'package:billetudo/features/budgets/domain/entities/budget_with_progress.dart';
import 'package:billetudo/features/budgets/domain/usecases/watch_featured_budget_progress.dart';
import 'package:billetudo/features/settings/domain/entities/app_settings.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../../settings/domain/usecases/app_settings_repository_mock.dart';
import '../budget_fixtures.dart';
import 'budget_repository_mock.dart';

/// Home's hero (`design-system/billetudo/pages/ajustes.md`, "Presupuesto
/// destacado"): combines active budgets with settings so a manual pick wins,
/// and auto-falls-back the moment the picked budget stops being active.
void main() {
  late MockBudgetRepository budgetRepository;
  late MockAppSettingsRepository settingsRepository;
  late WatchFeaturedBudgetProgress useCase;

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

  setUp(() {
    budgetRepository = MockBudgetRepository();
    settingsRepository = MockAppSettingsRepository();
    useCase = WatchFeaturedBudgetProgress(budgetRepository, settingsRepository);
  });

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

  test('emits the automatic pick when featuredBudgetId is null', () async {
    final target = entry(id: 'b1', createdAt: DateTime(2026, 6, 1));
    when(() => budgetRepository.watchActiveBudgets()).thenAnswer(
      (_) => Stream<Result<List<BudgetWithProgress>>>.value(Right([target])),
    );
    when(() => settingsRepository.watchSettings()).thenAnswer(
      (_) => Stream<Result<AppSettings>>.value(
        const Right(AppSettings.defaults()),
      ),
    );

    final result = await useCase().first;

    expect(result.getRight().toNullable(), target);
  });

  test('emits the featured budget over the automatic pick', () async {
    final autoWinner = entry(id: 'auto', createdAt: DateTime(2026, 6, 1));
    final featured = entry(
      id: 'featured',
      period: BudgetPeriod.weekly,
      createdAt: DateTime(2026, 1, 1),
    );
    when(() => budgetRepository.watchActiveBudgets()).thenAnswer(
      (_) => Stream<Result<List<BudgetWithProgress>>>.value(
        Right([autoWinner, featured]),
      ),
    );
    when(() => settingsRepository.watchSettings()).thenAnswer(
      (_) => Stream<Result<AppSettings>>.value(
        const Right(
          AppSettings(
            zeroBasedEnabled: false,
            categoriesSeeded: true,
            onboardingCompleted: true,
            featuredBudgetId: 'featured',
            featuredBudgetMode: FeaturedBudgetMode.manual,
          ),
        ),
      ),
    );

    final result = await useCase().first;

    expect(result.getRight().toNullable()?.budget.id, 'featured');
  });

  test(
      'falls back to the automatic pick as soon as the featured budget '
      'drops out of the active list (archived/deleted)', () async {
    final autoWinner = entry(id: 'auto', createdAt: DateTime(2026, 6, 1));
    final budgetsController =
        StreamController<Result<List<BudgetWithProgress>>>.broadcast();
    when(() => budgetRepository.watchActiveBudgets())
        .thenAnswer((_) => budgetsController.stream);
    when(() => settingsRepository.watchSettings()).thenAnswer(
      (_) => Stream<Result<AppSettings>>.value(
        const Right(
          AppSettings(
            zeroBasedEnabled: false,
            categoriesSeeded: true,
            onboardingCompleted: true,
            featuredBudgetId: 'gone',
            featuredBudgetMode: FeaturedBudgetMode.manual,
          ),
        ),
      ),
    );

    final emissions = <Result<BudgetWithProgress?>>[];
    final subscription = useCase().listen(emissions.add);

    // First tick: the featured budget is still active.
    final featured = entry(id: 'gone', createdAt: DateTime(2026, 1, 1));
    budgetsController.add(Right([featured, autoWinner]));
    await Future<void>.delayed(Duration.zero);

    // Second tick: it got archived/deleted and dropped out of the active
    // list — the hero must fall back automatically, no re-selection needed.
    budgetsController.add(Right([autoWinner]));
    await Future<void>.delayed(Duration.zero);

    await subscription.cancel();
    await budgetsController.close();

    expect(emissions, hasLength(2));
    expect(emissions[0].getRight().toNullable()?.budget.id, 'gone');
    expect(emissions[1].getRight().toNullable()?.budget.id, 'auto');
  });

  test('propagates a budget repository failure as Left', () async {
    const failure = DatabaseFailure('boom');
    when(() => budgetRepository.watchActiveBudgets()).thenAnswer(
      (_) => Stream<Result<List<BudgetWithProgress>>>.value(
        const Left(failure),
      ),
    );
    when(() => settingsRepository.watchSettings()).thenAnswer(
      (_) => Stream<Result<AppSettings>>.value(
        const Right(AppSettings.defaults()),
      ),
    );

    final result = await useCase().first;

    expect(result.getLeft().toNullable(), failure);
  });

  test(
      'round-trip: manually featuring a budget then clearing it stays null '
      '(mode: none), even with a single active global-monthly budget that '
      'would otherwise auto-qualify', () async {
    final onlyGlobalMonthly = entry(id: 'b1', createdAt: DateTime(2026, 6, 1));
    when(() => budgetRepository.watchActiveBudgets()).thenAnswer(
      (_) => Stream<Result<List<BudgetWithProgress>>>.value(
        Right([onlyGlobalMonthly]),
      ),
    );
    final settingsController = StreamController<Result<AppSettings>>();
    when(() => settingsRepository.watchSettings())
        .thenAnswer((_) => settingsController.stream);

    final emissions = <Result<BudgetWithProgress?>>[];
    final subscription = useCase().listen(emissions.add);

    // Manually featured — same single budget, just picked explicitly.
    settingsController.add(
      const Right(
        AppSettings(
          zeroBasedEnabled: false,
          categoriesSeeded: true,
          onboardingCompleted: true,
          featuredBudgetId: 'b1',
          featuredBudgetMode: FeaturedBudgetMode.manual,
        ),
      ),
    );
    await Future<void>.delayed(Duration.zero);

    // Cleared: `ClearFeaturedBudget` sets mode `none`, not `automatic` — the
    // single global-monthly budget must NOT be auto-picked back.
    settingsController.add(
      const Right(
        AppSettings(
          zeroBasedEnabled: false,
          categoriesSeeded: true,
          onboardingCompleted: true,
          featuredBudgetMode: FeaturedBudgetMode.none,
        ),
      ),
    );
    await Future<void>.delayed(Duration.zero);

    await subscription.cancel();
    await settingsController.close();

    expect(emissions, hasLength(2));
    expect(emissions[0].getRight().toNullable()?.budget.id, 'b1');
    expect(emissions[1].getRight().toNullable(), isNull);
  });

  test('propagates a settings repository failure as Left', () async {
    const failure = DatabaseFailure('boom');
    when(() => budgetRepository.watchActiveBudgets()).thenAnswer(
      (_) => Stream<Result<List<BudgetWithProgress>>>.value(
        const Right(<BudgetWithProgress>[]),
      ),
    );
    when(() => settingsRepository.watchSettings()).thenAnswer(
      (_) => Stream<Result<AppSettings>>.value(const Left(failure)),
    );

    final result = await useCase().first;

    expect(result.getLeft().toNullable(), failure);
  });
}
