import 'package:billetudo/features/budgets/domain/entities/zero_based_summary.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ZeroBasedSummary.assignedFraction', () {
    test('is the assigned share of the income', () {
      const summary = ZeroBasedSummary(
        currency: 'COP',
        incomeMinor: 400000,
        assignedMinor: 100000,
      );

      expect(summary.assignedFraction, 0.25);
      expect(summary.isAllAssigned, isFalse);
      expect(summary.isOverAssigned, isFalse);
    });

    test('tops out at 1 when over-assigned, instead of overflowing', () {
      const summary = ZeroBasedSummary(
        currency: 'COP',
        incomeMinor: 100000,
        assignedMinor: 250000,
      );

      expect(summary.assignedFraction, 1);
      expect(summary.isOverAssigned, isTrue);
    });

    test('is empty with no income and with nothing assigned', () {
      expect(
        const ZeroBasedSummary(
          currency: 'COP',
          incomeMinor: 0,
          assignedMinor: 0,
        ).assignedFraction,
        0,
      );
      expect(
        const ZeroBasedSummary(
          currency: 'COP',
          incomeMinor: 500000,
          assignedMinor: 0,
        ).assignedFraction,
        0,
      );
    });

    test('is full and all-assigned when income equals assigned', () {
      const summary = ZeroBasedSummary(
        currency: 'COP',
        incomeMinor: 500000,
        assignedMinor: 500000,
      );

      expect(summary.assignedFraction, 1);
      expect(summary.isAllAssigned, isTrue);
    });
  });
}
