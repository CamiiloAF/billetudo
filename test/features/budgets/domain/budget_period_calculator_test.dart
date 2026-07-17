import 'package:billetudo/features/budgets/domain/entities/budget.dart';
import 'package:billetudo/features/budgets/domain/entities/budget_period_window.dart';
import 'package:billetudo/features/budgets/domain/services/budget_period_calculator.dart';
import 'package:flutter_test/flutter_test.dart';

import 'budget_fixtures.dart';

void main() {
  group('BudgetPeriodCalculator — weekly', () {
    test('advances in whole 7-day blocks from the anchor', () {
      final calc = BudgetPeriodCalculator(
        buildBudget(period: BudgetPeriod.weekly, startDate: DateTime(2024, 1, 1)),
      );
      final window = calc.windowAt(2, DateTime(2024, 1, 16));
      expect(window.start, DateTime(2024, 1, 15));
      expect(window.endExclusive, DateTime(2024, 1, 22));
      expect(window.status, BudgetWindowStatus.current);
    });
  });

  group('BudgetPeriodCalculator — monthly', () {
    test('anchors to the start day-of-month', () {
      final calc = BudgetPeriodCalculator(
        buildBudget(startDate: DateTime(2024, 1, 21)),
      );
      final window = calc.windowAt(0, DateTime(2024, 1, 25));
      expect(window.start, DateTime(2024, 1, 21));
      expect(window.endExclusive, DateTime(2024, 2, 21));
    });

    test('clamps day 31 to the last day of a short month (leap Feb)', () {
      final calc = BudgetPeriodCalculator(
        buildBudget(startDate: DateTime(2024, 1, 31)),
      );
      expect(calc.windowAt(1, DateTime(2024, 2, 10)).start, DateTime(2024, 2, 29));
      expect(calc.windowAt(2, DateTime(2024, 3, 10)).start, DateTime(2024, 3, 31));
    });

    test('clamps day 31 to Feb 28 in a non-leap year', () {
      final calc = BudgetPeriodCalculator(
        buildBudget(startDate: DateTime(2023, 1, 31)),
      );
      expect(calc.windowAt(1, DateTime(2023, 2, 10)).start, DateTime(2023, 2, 28));
    });

    test('currentWindow lands on the period containing today', () {
      final calc = BudgetPeriodCalculator(
        buildBudget(startDate: DateTime(2024, 1, 10)),
      );
      final window = calc.currentWindow(DateTime(2024, 3, 15));
      expect(window.index, 2);
      expect(window.start, DateTime(2024, 3, 10));
      expect(window.endExclusive, DateTime(2024, 4, 10));
      expect(window.status, BudgetWindowStatus.current);
    });
  });

  group('BudgetPeriodCalculator — yearly', () {
    test('clamps a Feb 29 anchor to Feb 28 in a non-leap year', () {
      final calc = BudgetPeriodCalculator(
        buildBudget(period: BudgetPeriod.yearly, startDate: DateTime(2024, 2, 29)),
      );
      expect(calc.windowAt(0, DateTime(2024, 6, 1)).start, DateTime(2024, 2, 29));
      expect(calc.windowAt(1, DateTime(2025, 6, 1)).start, DateTime(2025, 2, 28));
    });
  });

  group('BudgetPeriodCalculator — biweekly (semi-monthly)', () {
    test('anchor day 1 -> 1–15 and 16–end (two periods per month)', () {
      final calc = BudgetPeriodCalculator(
        buildBudget(period: BudgetPeriod.biweekly, startDate: DateTime(2024, 1, 1)),
      );
      final first = calc.windowAt(0, DateTime(2024, 1, 5));
      expect(first.start, DateTime(2024, 1, 1));
      expect(first.endExclusive, DateTime(2024, 1, 16)); // 1–15 inclusive

      final second = calc.windowAt(1, DateTime(2024, 1, 20));
      expect(second.start, DateTime(2024, 1, 16));
      expect(second.endExclusive, DateTime(2024, 2, 1)); // 16–31 inclusive

      final third = calc.windowAt(2, DateTime(2024, 2, 5));
      expect(third.start, DateTime(2024, 2, 1));
      expect(third.endExclusive, DateTime(2024, 2, 16));
    });

    test('anchor day 21 -> 21–5 and 6–20 (wraps into the next month)', () {
      final calc = BudgetPeriodCalculator(
        buildBudget(period: BudgetPeriod.biweekly, startDate: DateTime(2024, 1, 21)),
      );
      final first = calc.windowAt(0, DateTime(2024, 1, 25));
      expect(first.start, DateTime(2024, 1, 21));
      expect(first.endExclusive, DateTime(2024, 2, 6)); // 21–Feb5 inclusive

      final second = calc.windowAt(1, DateTime(2024, 2, 10));
      expect(second.start, DateTime(2024, 2, 6));
      expect(second.endExclusive, DateTime(2024, 2, 21)); // 6–20 inclusive

      final third = calc.windowAt(2, DateTime(2024, 3, 1));
      expect(third.start, DateTime(2024, 2, 21));
      expect(third.endExclusive, DateTime(2024, 3, 6));
    });

    test('currentWindow selects the semi-monthly period containing today', () {
      final calc = BudgetPeriodCalculator(
        buildBudget(period: BudgetPeriod.biweekly, startDate: DateTime(2024, 1, 21)),
      );
      final window = calc.currentWindow(DateTime(2024, 2, 15));
      expect(window.start, DateTime(2024, 2, 6));
      expect(window.endExclusive, DateTime(2024, 2, 21));
    });
  });

  group('BudgetPeriodCalculator — one-off / custom', () {
    test('is a single inclusive window with no navigation', () {
      final calc = BudgetPeriodCalculator(
        buildBudget(
          period: BudgetPeriod.custom,
          recurring: false,
          startDate: DateTime(2024, 1, 1),
          endDate: DateTime(2024, 1, 31),
        ),
      );
      final window = calc.windowAt(0, DateTime(2024, 1, 10));
      expect(window.start, DateTime(2024, 1, 1));
      // endDate inclusive -> exclusive end is the following day.
      expect(window.endExclusive, DateTime(2024, 2, 1));
      expect(window.hasPrevious, isFalse);
      expect(window.hasNext, isFalse);
    });

    test('currentWindow clamps to the single window when today is past it', () {
      final calc = BudgetPeriodCalculator(
        buildBudget(
          period: BudgetPeriod.custom,
          recurring: false,
          startDate: DateTime(2024, 1, 1),
          endDate: DateTime(2024, 1, 31),
        ),
      );
      final window = calc.currentWindow(DateTime(2024, 6, 1));
      expect(window.index, 0);
      expect(window.status, BudgetWindowStatus.past);
    });
  });

  group('BudgetPeriodCalculator — navigation bounds', () {
    test('no previous at index 0', () {
      final calc = BudgetPeriodCalculator(
        buildBudget(startDate: DateTime(2024, 1, 1)),
      );
      expect(calc.windowAt(0, DateTime(2024, 1, 5)).hasPrevious, isFalse);
      expect(calc.windowAt(1, DateTime(2024, 2, 5)).hasPrevious, isTrue);
    });

    test('a periodic budget renews forever (hasNext stays true)', () {
      final calc = BudgetPeriodCalculator(
        buildBudget(startDate: DateTime(2024, 1, 1)),
      );
      expect(calc.windowAt(9, DateTime(2024, 1, 5)).hasNext, isTrue);
    });

    test('endDate caps the last navigable window', () {
      final calc = BudgetPeriodCalculator(
        buildBudget(
          startDate: DateTime(2024, 1, 1),
          endDate: DateTime(2024, 3, 15),
        ),
      );
      // Windows start Jan1/Feb1/Mar1/Apr1; Apr1 is past the endDate, so index 2
      // is the last one.
      expect(calc.windowAt(2, DateTime(2024, 3, 5)).hasNext, isFalse);
      expect(calc.windowAt(1, DateTime(2024, 2, 5)).hasNext, isTrue);
    });
  });
}
