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

  group('open/closed split (extension, HU-07)', () {
    DebtWithBalance closedItem({
      required String id,
      required DebtDirection direction,
      required String currency,
      required int paid,
    }) =>
        DebtWithBalance(
          debt: buildDebt(
            id: id,
            direction: direction,
            currency: currency,
            closedAt: DateTime(2026, 6, 1),
          ),
          balance: DebtBalance(
            principalMinor: paid,
            totalIncreasesMinor: paid,
            totalDecreasesMinor: paid,
            interestAccruedMinor: 0,
          ),
        );

    test('openDebts/closedDebts partition by closedAt', () {
      final open = item(
        direction: DebtDirection.iOwe,
        currency: 'COP',
        outstanding: 50000,
      );
      final closed = closedItem(
        id: 'd2',
        direction: DebtDirection.iOwe,
        currency: 'COP',
        paid: 30000,
      );

      final summary = DebtsSummary.from([open, closed]);

      expect(summary.openDebts, [open]);
      expect(summary.closedDebts, [closed]);
    });

    test('closedTotals segments "pagué"/"me pagaron" by currency, and a '
        'closed debt does not leak into totals (Activas)', () {
      final summary = DebtsSummary.from([
        closedItem(
          id: 'd1',
          direction: DebtDirection.iOwe,
          currency: 'COP',
          paid: 100000,
        ),
        closedItem(
          id: 'd2',
          direction: DebtDirection.owedToMe,
          currency: 'COP',
          paid: 40000,
        ),
        closedItem(
          id: 'd3',
          direction: DebtDirection.iOwe,
          currency: 'USD',
          paid: 500,
        ),
      ]);

      expect(summary.totals, isEmpty); // no open debts at all

      final cop =
          summary.closedTotals.firstWhere((t) => t.currency == 'COP');
      expect(cop.iOwePaidMinor, 100000);
      expect(cop.owedToMeCollectedMinor, 40000);

      final usd =
          summary.closedTotals.firstWhere((t) => t.currency == 'USD');
      expect(usd.iOwePaidMinor, 500);
      expect(usd.owedToMeCollectedMinor, 0);
    });

    test('mixing open and closed debts keeps totals and closedTotals '
        'independent of each other', () {
      final summary = DebtsSummary.from([
        item(direction: DebtDirection.iOwe, currency: 'COP', outstanding: 70000),
        closedItem(
          id: 'd2',
          direction: DebtDirection.iOwe,
          currency: 'COP',
          paid: 100000,
        ),
      ]);

      expect(summary.totals.single.iOweOutstandingMinor, 70000);
      expect(summary.closedTotals.single.iOwePaidMinor, 100000);
    });
  });
}
