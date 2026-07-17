import 'package:billetudo/features/budgets/domain/entities/period_income.dart';
import 'package:billetudo/features/budgets/domain/services/zero_based_summary_calculator.dart';
import 'package:flutter_test/flutter_test.dart';

import 'budget_fixtures.dart';

void main() {
  const calc = ZeroBasedSummaryCalculator();

  final now = DateTime(2026, 7, 16);

  PeriodIncome income({
    int amountMinor = 100000,
    String currency = 'COP',
    DateTime? date,
  }) =>
      PeriodIncome(
        amountMinor: amountMinor,
        currency: currency,
        date: date ?? DateTime(2026, 7, 10),
      );

  group('HU-06: nothing to show', () {
    test('returns null when there is no active budget and no income', () {
      final result = calc.summarize(
        activeBudgets: const [],
        income: const [],
        now: now,
      );
      expect(result, isNull);
    });
  });

  group('income − assigned = unassigned', () {
    test('sums assigned and income for the shared currency', () {
      final budgets = [
        buildBudget(
            id: 'b1',
            currency: 'COP',
            amountMinor: 200000,
            startDate: DateTime(2026, 1, 1)),
        buildBudget(
            id: 'b2',
            currency: 'COP',
            amountMinor: 150000,
            startDate: DateTime(2026, 1, 1)),
      ];
      final incomes = [
        income(amountMinor: 300000),
        income(amountMinor: 100000),
      ];

      final result = calc.summarize(
        activeBudgets: budgets,
        income: incomes,
        now: now,
      );

      expect(result, isNotNull);
      expect(result!.currency, 'COP');
      expect(result.assignedMinor, 350000);
      expect(result.incomeMinor, 400000);
      expect(result.unassignedMinor, 50000);
    });

    test('unassignedMinor is negative when over-assigned', () {
      final budgets = [
        buildBudget(
            id: 'b1',
            currency: 'COP',
            amountMinor: 500000,
            startDate: DateTime(2026, 1, 1)),
      ];
      final incomes = [income(amountMinor: 300000)];

      final result = calc.summarize(
        activeBudgets: budgets,
        income: incomes,
        now: now,
      );

      expect(result!.unassignedMinor, -200000);
    });
  });

  group('income is filtered to the calendar month of `now`', () {
    test('ignores income outside July 2026', () {
      final budgets = [
        buildBudget(
            id: 'b1',
            currency: 'COP',
            amountMinor: 100000,
            startDate: DateTime(2026, 1, 1)),
      ];
      final incomes = [
        income(amountMinor: 500000, date: DateTime(2026, 6, 30)),
        income(amountMinor: 700000, date: DateTime(2026, 8, 1)),
        income(amountMinor: 900000, date: DateTime(2026, 7, 1)),
        income(amountMinor: 100000, date: DateTime(2026, 7, 31)),
      ];

      final result = calc.summarize(
        activeBudgets: budgets,
        income: incomes,
        now: now,
      );

      expect(result!.incomeMinor, 1000000);
    });
  });

  group('reference currency', () {
    test('picks the currency most active budgets share', () {
      final budgets = [
        buildBudget(
            id: 'b1',
            currency: 'COP',
            amountMinor: 100000,
            startDate: DateTime(2026, 1, 1)),
        buildBudget(
            id: 'b2',
            currency: 'COP',
            amountMinor: 200000,
            startDate: DateTime(2026, 1, 1)),
        buildBudget(
            id: 'b3',
            currency: 'USD',
            amountMinor: 5000,
            startDate: DateTime(2026, 1, 1)),
      ];
      final incomes = [
        income(currency: 'USD', amountMinor: 100000),
      ];

      final result = calc.summarize(
        activeBudgets: budgets,
        income: incomes,
        now: now,
      );

      // COP has 2 budgets vs USD's 1, so COP wins even though all income is
      // in USD (and that USD income is excluded from the sums below).
      expect(result!.currency, 'COP');
      expect(result.assignedMinor, 300000);
      expect(result.incomeMinor, 0);
    });

    test('falls back to the month income currency when there is no budget', () {
      final incomes = [
        income(currency: 'USD', amountMinor: 5000),
        income(currency: 'USD', amountMinor: 3000),
        income(currency: 'COP', amountMinor: 100000),
      ];

      final result = calc.summarize(
        activeBudgets: const [],
        income: incomes,
        now: now,
      );

      expect(result!.currency, 'USD');
      expect(result.incomeMinor, 8000);
      expect(result.assignedMinor, 0);
    });

    test('ties break by alphabetical ISO code', () {
      final budgets = [
        buildBudget(
            id: 'b1',
            currency: 'USD',
            amountMinor: 5000,
            startDate: DateTime(2026, 1, 1)),
        buildBudget(
            id: 'b2',
            currency: 'COP',
            amountMinor: 100000,
            startDate: DateTime(2026, 1, 1)),
      ];

      final result = calc.summarize(
        activeBudgets: budgets,
        income: const [],
        now: now,
      );

      // One budget each: COP < USD alphabetically.
      expect(result!.currency, 'COP');
      expect(result.assignedMinor, 100000);
    });
  });
}
