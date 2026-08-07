import 'package:billetudo/features/budgets/domain/entities/budget.dart'
    show BudgetPeriod;
import 'package:billetudo/features/budgets/domain/entities/budget_period_window.dart';
import 'package:billetudo/features/budgets/domain/entities/budget_progress.dart';
import 'package:billetudo/features/budgets/domain/entities/budget_scope.dart';
import 'package:billetudo/features/budgets/domain/entities/budget_with_progress.dart';
import 'package:billetudo/features/budgets/domain/services/budget_hero_selector.dart';
import 'package:flutter_test/flutter_test.dart';

import '../budget_fixtures.dart';

/// Shared rule behind both `WatchGlobalMonthlyBudgetProgress` (no explicit
/// pick) and `WatchFeaturedBudgetProgress` (Ajustes' "Presupuesto
/// destacado"), `design-system/billetudo/pages/ajustes.md`.
void main() {
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

  group('without a featuredBudgetId (automatic fallback)', () {
    test('picks the global-monthly budget when it is the only one', () {
      final target = entry(id: 'b1', createdAt: DateTime(2026, 6, 1));

      expect(BudgetHeroSelector.pick([target]), target);
    });

    test('ignores budgets scoped to an account (not global)', () {
      final scoped = entry(
        id: 'b-account',
        scope: const BudgetScope(
          accounts: [BudgetScopeRef(id: 'acc-1', referentAlive: true)],
        ),
        createdAt: DateTime(2026, 6, 1),
      );

      expect(BudgetHeroSelector.pick([scoped]), isNull);
    });

    test('ignores global budgets on a non-monthly period', () {
      final weekly = entry(
        id: 'b-weekly',
        period: BudgetPeriod.weekly,
        createdAt: DateTime(2026, 6, 1),
      );

      expect(BudgetHeroSelector.pick([weekly]), isNull);
    });

    test('breaks ties by the most recently created qualifying budget', () {
      final older = entry(id: 'older', createdAt: DateTime(2026, 1, 1));
      final newer = entry(id: 'newer', createdAt: DateTime(2026, 6, 15));
      final middle = entry(id: 'middle', createdAt: DateTime(2026, 3, 1));

      final result = BudgetHeroSelector.pick([older, newer, middle]);

      expect(result?.budget.id, 'newer');
    });

    test('returns null when no active budget qualifies', () {
      expect(BudgetHeroSelector.pick(const []), isNull);
    });

    test(
        'picks a global-monthly budget anchored on a day other than 1, and '
        'keeps its real (non-calendar-month) window — bugfix '
        'home-hero-period-stepper', () {
      final anchoredWindow = BudgetPeriodWindow(
        start: DateTime(2026, 7, 27),
        endExclusive: DateTime(2026, 8, 27),
        index: 3,
        status: BudgetWindowStatus.current,
        hasPrevious: true,
        hasNext: true,
      );
      final anchored = BudgetWithProgress(
        budget: buildBudget(
          id: 'b-anchored',
          period: BudgetPeriod.monthly,
          startDate: DateTime(2026, 4, 27),
          createdAt: DateTime(2026, 6, 1),
        ),
        scope: const BudgetScope.empty(),
        window: anchoredWindow,
        progress: progress,
      );

      final result = BudgetHeroSelector.pick([anchored]);

      expect(result?.budget.id, 'b-anchored');
      expect(result?.window, anchoredWindow);
      expect(result?.window.start, DateTime(2026, 7, 27));
    });
  });

  group('with a featuredBudgetId (manual pick)', () {
    test('wins over the automatic global-monthly pick when present', () {
      final autoWinner = entry(id: 'auto', createdAt: DateTime(2026, 6, 1));
      final featured = entry(
        id: 'featured',
        scope: const BudgetScope(
          accounts: [BudgetScopeRef(id: 'acc-1', referentAlive: true)],
        ),
        period: BudgetPeriod.weekly,
        createdAt: DateTime(2026, 1, 1),
      );

      final result = BudgetHeroSelector.pick(
        [autoWinner, featured],
        featuredBudgetId: 'featured',
      );

      expect(result?.budget.id, 'featured');
    });

    test(
        'falls back to the automatic pick when the featured id is not among '
        'the active budgets (archived/deleted)', () {
      final autoWinner = entry(id: 'auto', createdAt: DateTime(2026, 6, 1));

      final result = BudgetHeroSelector.pick(
        [autoWinner],
        featuredBudgetId: 'no-longer-active',
      );

      expect(result?.budget.id, 'auto');
    });

    test('falls back to null when the featured id is gone and nothing else '
        'qualifies automatically', () {
      final scoped = entry(
        id: 'scoped',
        scope: const BudgetScope(
          accounts: [BudgetScopeRef(id: 'acc-1', referentAlive: true)],
        ),
        createdAt: DateTime(2026, 6, 1),
      );

      final result = BudgetHeroSelector.pick(
        [scoped],
        featuredBudgetId: 'gone',
      );

      expect(result, isNull);
    });
  });
}
