import 'package:billetudo/features/debts/domain/entities/debt.dart';
import 'package:billetudo/features/debts/domain/entities/debt_balance.dart';
import 'package:billetudo/features/debts/domain/entities/debt_with_balance.dart';
import 'package:billetudo/features/debts/domain/entities/debts_summary.dart';
import 'package:flutter_test/flutter_test.dart';

import 'debt_test_fixtures.dart';

void main() {
  DebtWithBalance item({
    required DebtDirection direction,
    required String currency,
    required int outstanding,
  }) =>
      DebtWithBalance(
        debt: buildDebt(direction: direction, currency: currency),
        balance: DebtBalance(
          principalMinor: outstanding,
          totalIncreasesMinor: outstanding,
          totalDecreasesMinor: 0,
          interestAccruedMinor: 0,
        ),
      );

  test('segments totals by currency and direction (no normalization)', () {
    final summary = DebtsSummary.from([
      item(
        direction: DebtDirection.iOwe,
        currency: 'COP',
        outstanding: 100000,
      ),
      item(
        direction: DebtDirection.iOwe,
        currency: 'COP',
        outstanding: 50000,
      ),
      item(
        direction: DebtDirection.owedToMe,
        currency: 'COP',
        outstanding: 30000,
      ),
      item(direction: DebtDirection.iOwe, currency: 'USD', outstanding: 900),
    ]);

    expect(summary.totals.length, 2);

    final cop = summary.totals.firstWhere((t) => t.currency == 'COP');
    expect(cop.iOweOutstandingMinor, 150000);
    expect(cop.owedToMeOutstandingMinor, 30000);

    final usd = summary.totals.firstWhere((t) => t.currency == 'USD');
    expect(usd.iOweOutstandingMinor, 900);
    expect(usd.owedToMeOutstandingMinor, 0);
  });

  test('an empty list yields no totals', () {
    expect(DebtsSummary.from(const []).totals, isEmpty);
  });
}
