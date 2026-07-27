import 'package:billetudo/features/debts/domain/services/debt_interest_calculator.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const calc = DebtInterestCalculator();

  group('accruedInterestMinor', () {
    test('one day at 36.5% annual is exactly 0.1% of the balance', () {
      // dailyRate = 3650/10000/365 = 0.001 -> 1,000,000 * 0.001 = 1000.
      final interest = calc.accruedInterestMinor(
        balanceMinor: 1000000,
        rateBps: 3650,
        days: 1,
      );

      expect(interest, 1000);
    });

    test('compounds: 10 days grows more than 10× the single-day interest', () {
      final oneDay = calc.accruedInterestMinor(
        balanceMinor: 1000000,
        rateBps: 3650,
        days: 1,
      );
      final tenDays = calc.accruedInterestMinor(
        balanceMinor: 1000000,
        rateBps: 3650,
        days: 10,
      );

      expect(tenDays, greaterThan(oneDay * 10));
    });

    test('rounds to whole cents (half away from zero)', () {
      // A tiny balance so the fractional cent is visible.
      final interest = calc.accruedInterestMinor(
        balanceMinor: 1005,
        rateBps: 3650,
        days: 1,
      );
      // 1005 * 0.001 = 1.005 -> rounds to 1.
      expect(interest, 1);
    });

    test('returns 0 for a non-positive balance, rate or day count', () {
      expect(
        calc.accruedInterestMinor(balanceMinor: 0, rateBps: 3650, days: 5),
        0,
      );
      expect(
        calc.accruedInterestMinor(balanceMinor: 1000, rateBps: 0, days: 5),
        0,
      );
      expect(
        calc.accruedInterestMinor(balanceMinor: 1000, rateBps: 3650, days: 0),
        0,
      );
      expect(
        calc.accruedInterestMinor(
          balanceMinor: -1000,
          rateBps: 3650,
          days: 5,
        ),
        0,
      );
    });
  });

  group('projectPayoff', () {
    test('a covering installment clears the debt in a finite count', () {
      final projection = calc.projectPayoff(
        balanceMinor: 1000000,
        rateBps: 1200, // 12% annual
        installmentMinor: 100000,
        from: DateTime(2026, 1, 1),
      );

      expect(projection, isNotNull);
      expect(projection!.installmentCount, greaterThan(0));
      expect(projection.totalInterestMinor, greaterThan(0));
      // Repays principal + interest.
      expect(projection.totalPaidMinor, greaterThan(1000000));
      expect(projection.payoffDate.isAfter(DateTime(2026, 1, 1)), isTrue);
    });

    test('an installment below the first months interest never pays off', () {
      final projection = calc.projectPayoff(
        balanceMinor: 10000000,
        rateBps: 6000, // 60% annual -> heavy monthly interest
        installmentMinor: 1000, // absurdly small
        from: DateTime(2026, 1, 1),
      );

      expect(projection, isNull);
    });

    test('a non-positive balance or installment returns null', () {
      expect(
        calc.projectPayoff(
          balanceMinor: 0,
          rateBps: 1200,
          installmentMinor: 100000,
          from: DateTime(2026, 1, 1),
        ),
        isNull,
      );
      expect(
        calc.projectPayoff(
          balanceMinor: 100000,
          rateBps: 1200,
          installmentMinor: 0,
          from: DateTime(2026, 1, 1),
        ),
        isNull,
      );
    });

    test('a rate-free debt pays off in ceil(balance / installment)', () {
      final projection = calc.projectPayoff(
        balanceMinor: 100000,
        rateBps: 0,
        installmentMinor: 30000,
        from: DateTime(2026, 1, 1),
      );

      expect(projection, isNotNull);
      expect(projection!.installmentCount, 4); // 30k×3 + 10k
      expect(projection.totalInterestMinor, 0);
      expect(projection.totalPaidMinor, 100000);
    });
  });
}
