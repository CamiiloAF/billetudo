import 'package:billetudo/features/budgets/domain/entities/budget_progress.dart';
import 'package:flutter_test/flutter_test.dart';

/// HU-12: `scheduledMinor` and its derived fractions, and the guarantee that
/// `isOverspent` stays exclusively driven by `spentMinor` (criterion 6).
void main() {
  group('scheduledMinor defaults to 0 (pre-HU-12 call sites)', () {
    test('a BudgetProgress built without scheduledMinor has none programado',
        () {
      const progress =
          BudgetProgress(amountMinor: 1000, spentMinor: 400, daysLeft: 5);
      expect(progress.scheduledMinor, 0);
      expect(progress.scheduledFraction, 0);
    });
  });

  group('isOverspent (criterion 6)', () {
    test('spent <= amount but spent + scheduled > amount is NOT overspent', () {
      const progress = BudgetProgress(
        amountMinor: 1000,
        spentMinor: 600,
        scheduledMinor: 800,
        daysLeft: 5,
      );
      expect(progress.isOverspent, isFalse);
    });

    test('only actual spend past the amount is overspent', () {
      const progress = BudgetProgress(
        amountMinor: 1000,
        spentMinor: 1200,
        daysLeft: 0,
      );
      expect(progress.isOverspent, isTrue);
    });
  });

  group('scheduledFraction (criterion 5)', () {
    test('renders its own width when there is room left', () {
      const progress = BudgetProgress(
        amountMinor: 1000,
        spentMinor: 300,
        scheduledMinor: 200,
        daysLeft: 5,
      );
      expect(progress.fraction, closeTo(0.3, 1e-9));
      expect(progress.scheduledFraction, closeTo(0.2, 1e-9));
    });

    test(
        'clamps to the room left so the two segments never overlap past '
        '100%', () {
      const progress = BudgetProgress(
        amountMinor: 1000,
        spentMinor: 800,
        scheduledMinor: 500,
        daysLeft: 5,
      );
      expect(progress.fraction, closeTo(0.8, 1e-9));
      // Only 0.2 of room left, even though scheduled alone is 0.5.
      expect(progress.scheduledFraction, closeTo(0.2, 1e-9));
    });

    test('is 0 once already overspent (no room left)', () {
      const progress = BudgetProgress(
        amountMinor: 1000,
        spentMinor: 1200,
        scheduledMinor: 500,
        daysLeft: 0,
      );
      expect(progress.scheduledFraction, 0);
    });

    test('is 0 when there is nothing scheduled', () {
      const progress = BudgetProgress(
        amountMinor: 1000,
        spentMinor: 100,
        daysLeft: 5,
      );
      expect(progress.scheduledFraction, 0);
    });
  });

  group('committedFraction', () {
    test('sums spent and scheduled as a fraction of the amount', () {
      const progress = BudgetProgress(
        amountMinor: 1000,
        spentMinor: 300,
        scheduledMinor: 900,
        daysLeft: 5,
      );
      expect(progress.committedFraction, closeTo(1.2, 1e-9));
    });
  });

  group('isScheduledOverspendRisk (HU-12)', () {
    test(
        'activates when spent + scheduled exceeds the amount but spend '
        'alone does not', () {
      const progress = BudgetProgress(
        amountMinor: 600000,
        spentMinor: 420000,
        scheduledMinor: 270000,
        daysLeft: 18,
      );
      expect(progress.isScheduledOverspendRisk, isTrue);
      expect(progress.scheduledOverageMinor, 90000);
    });

    test(
        'does not activate when the projection stays within the amount '
        '("programado sano")', () {
      const progress = BudgetProgress(
        amountMinor: 600000,
        spentMinor: 492000,
        scheduledMinor: 60000,
        daysLeft: 18,
      );
      expect(progress.isScheduledOverspendRisk, isFalse);
      expect(progress.scheduledOverageMinor, 0);
      expect(progress.committedPercent, 92);
    });

    test(
        'is mutually exclusive with isOverspent: real overspend never '
        'flips it on, no matter how much is scheduled', () {
      const progress = BudgetProgress(
        amountMinor: 1000,
        spentMinor: 1200,
        scheduledMinor: 500,
        daysLeft: 0,
      );
      expect(progress.isOverspent, isTrue);
      expect(progress.isScheduledOverspendRisk, isFalse);
      expect(progress.scheduledOverageMinor, 0);
    });

    test(
        'does not activate with nothing scheduled, even past 100% spent '
        'is handled by isOverspent instead', () {
      const progress = BudgetProgress(
        amountMinor: 1000,
        spentMinor: 900,
        daysLeft: 5,
      );
      expect(progress.isScheduledOverspendRisk, isFalse);
    });
  });
}
