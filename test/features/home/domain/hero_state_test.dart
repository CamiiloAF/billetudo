import 'package:billetudo/features/budgets/domain/entities/budget_progress.dart';
import 'package:billetudo/features/home/domain/entities/hero_state.dart';
import 'package:flutter_test/flutter_test.dart';

import 'home_hero_fixtures.dart';

/// The 7 hero states (`design-system/billetudo/pages/inicio.md` § "Hero se
/// comprime...") resolved purely from `BudgetProgress` + `hasAnyBudget`.
void main() {
  group('sin presupuesto destacado', () {
    test('nunca creó uno -> noBudgetEverCreated', () {
      final state = HomeHeroStateResolver.resolve(
        featuredBudget: null,
        hasAnyBudget: false,
      );

      expect(state, HomeHeroState.noBudgetEverCreated);
    });

    test('tiene presupuestos pero ninguno destacado -> noBudgetFeatured', () {
      final state = HomeHeroStateResolver.resolve(
        featuredBudget: null,
        hasAnyBudget: true,
      );

      expect(state, HomeHeroState.noBudgetFeatured);
    });
  });

  group('con presupuesto destacado', () {
    test('gasto bajo -> healthy', () {
      final budget = buildBudgetWithProgress(
        createdAt: DateTime(2026, 1, 1),
        progress: const BudgetProgress(
            amountMinor: 600000, spentMinor: 100000, daysLeft: 10),
      );

      final state = HomeHeroStateResolver.resolve(
        featuredBudget: budget,
        hasAnyBudget: true,
      );

      expect(state, HomeHeroState.healthy);
    });

    test('cerca del límite (>=90%, sin sobregasto) -> nearLimit', () {
      final budget = buildBudgetWithProgress(
        createdAt: DateTime(2026, 1, 1),
        progress: const BudgetProgress(
            amountMinor: 100000, spentMinor: 97000, daysLeft: 2),
      );

      final state = HomeHeroStateResolver.resolve(
        featuredBudget: budget,
        hasAnyBudget: true,
      );

      expect(state, HomeHeroState.nearLimit);
    });

    test('exactamente 100% -> atLimit', () {
      final budget = buildBudgetWithProgress(
        createdAt: DateTime(2026, 1, 1),
        progress: const BudgetProgress(
            amountMinor: 100000, spentMinor: 100000, daysLeft: 0),
      );

      final state = HomeHeroStateResolver.resolve(
        featuredBudget: budget,
        hasAnyBudget: true,
      );

      expect(state, HomeHeroState.atLimit);
    });

    test(
        'gasto real bajo la meta pero proyección de programados la excede '
        '-> scheduledOverspendRisk', () {
      final budget = buildBudgetWithProgress(
        createdAt: DateTime(2026, 1, 1),
        progress: const BudgetProgress(
          amountMinor: 100000,
          spentMinor: 50000,
          daysLeft: 5,
          scheduledMinor: 60000,
        ),
      );

      final state = HomeHeroStateResolver.resolve(
        featuredBudget: budget,
        hasAnyBudget: true,
      );

      expect(state, HomeHeroState.scheduledOverspendRisk);
    });

    test(
        'gasto real por encima del monto -> overspent, aun con proyección '
        'de programados también fuera de rango', () {
      final budget = buildBudgetWithProgress(
        createdAt: DateTime(2026, 1, 1),
        progress: const BudgetProgress(
          amountMinor: 100000,
          spentMinor: 150000,
          daysLeft: 0,
          scheduledMinor: 20000,
        ),
      );

      final state = HomeHeroStateResolver.resolve(
        featuredBudget: budget,
        hasAnyBudget: true,
      );

      expect(state, HomeHeroState.overspent);
    });
  });
}
