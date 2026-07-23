import 'package:billetudo/features/debts/domain/entities/debt.dart';
import 'package:billetudo/features/debts/domain/entities/debt_entry.dart';
import 'package:billetudo/features/debts/domain/entities/debt_ledger_entry.dart';
import 'package:billetudo/features/debts/domain/services/debt_balance_calculator.dart';
import 'package:billetudo/features/transactions/domain/entities/transaction.dart';
import 'package:flutter_test/flutter_test.dart';

import 'debt_test_fixtures.dart';

void main() {
  const calc = DebtBalanceCalculator();

  group('cash events × direction × type', () {
    test('iOwe + income = disbursement (increases)', () {
      final balance = calc.calculate(
        debt: buildDebt(direction: DebtDirection.iOwe),
        entries: const [],
        cashEvents: [
          buildCashEvent(type: TransactionType.income, amountMinor: 50000),
        ],
      );

      expect(balance.totalIncreasesMinor, 50000);
      expect(balance.totalDecreasesMinor, 0);
      expect(balance.outstandingMinor, 50000);
    });

    test(
      'registro inicial (principal 0 + desembolso \$X) deriva \$X, no 2X',
      () {
        // The anti-double-count invariant (item 2): a registro debt stores a 0
        // principal and its opening lives in the linked disbursement, so the
        // opening figure is counted exactly once.
        final balance = calc.calculate(
          debt: buildDebt(
            direction: DebtDirection.iOwe,
            principalMinor: 0,
            initialTransactionId: 't-open',
          ),
          entries: const [],
          cashEvents: [
            buildCashEvent(
              transactionId: 't-open',
              type: TransactionType.income,
              amountMinor: 4200000,
            ),
          ],
        );

        expect(balance.outstandingMinor, 4200000);
      },
    );

    test('iOwe + expense = abono (reduces)', () {
      final balance = calc.calculate(
        debt: buildDebt(direction: DebtDirection.iOwe, principalMinor: 50000),
        entries: const [],
        cashEvents: [
          buildCashEvent(type: TransactionType.expense, amountMinor: 20000),
        ],
      );

      expect(balance.totalIncreasesMinor, 50000);
      expect(balance.totalDecreasesMinor, 20000);
      expect(balance.outstandingMinor, 30000);
    });

    test('owedToMe + expense = desembolso (increases)', () {
      final balance = calc.calculate(
        debt: buildDebt(direction: DebtDirection.owedToMe),
        entries: const [],
        cashEvents: [
          buildCashEvent(type: TransactionType.expense, amountMinor: 80000),
        ],
      );

      expect(balance.totalIncreasesMinor, 80000);
      expect(balance.outstandingMinor, 80000);
    });

    test('owedToMe + income = me pagaron (reduces)', () {
      final balance = calc.calculate(
        debt: buildDebt(
          direction: DebtDirection.owedToMe,
          principalMinor: 80000,
        ),
        entries: const [],
        cashEvents: [
          buildCashEvent(type: TransactionType.income, amountMinor: 30000),
        ],
      );

      expect(balance.totalDecreasesMinor, 30000);
      expect(balance.outstandingMinor, 50000);
    });

    test('a transfer with a debt id contributes nothing (defensive)', () {
      final balance = calc.calculate(
        debt: buildDebt(direction: DebtDirection.iOwe, principalMinor: 10000),
        entries: const [],
        cashEvents: [
          buildCashEvent(type: TransactionType.transfer, amountMinor: 99999),
        ],
      );

      expect(balance.outstandingMinor, 10000);
    });
  });

  group('ledger entries (the 4 kinds)', () {
    test('interestAccrual increases and is tracked separately', () {
      final balance = calc.calculate(
        debt: buildDebt(principalMinor: 100000),
        entries: [
          buildEntry(kind: DebtEntryKind.interestAccrual, amountMinor: 1500),
        ],
        cashEvents: const [],
      );

      expect(balance.interestAccruedMinor, 1500);
      expect(balance.totalIncreasesMinor, 101500);
      expect(balance.outstandingMinor, 101500);
    });

    test('disbursement entry increases (cash-less "No")', () {
      final balance = calc.calculate(
        debt: buildDebt(),
        entries: [
          buildEntry(kind: DebtEntryKind.disbursement, amountMinor: 40000),
        ],
        cashEvents: const [],
      );

      expect(balance.totalIncreasesMinor, 40000);
      expect(balance.outstandingMinor, 40000);
    });

    test('payment entry reduces (cash-less "No")', () {
      final balance = calc.calculate(
        debt: buildDebt(principalMinor: 40000),
        entries: [
          buildEntry(kind: DebtEntryKind.payment, amountMinor: -15000),
        ],
        cashEvents: const [],
      );

      expect(balance.totalDecreasesMinor, 15000);
      expect(balance.outstandingMinor, 25000);
    });

    test('manualAdjustment applies its sign either way', () {
      final up = calc.calculate(
        debt: buildDebt(principalMinor: 10000),
        entries: [
          buildEntry(kind: DebtEntryKind.manualAdjustment, amountMinor: 2000),
        ],
        cashEvents: const [],
      );
      final down = calc.calculate(
        debt: buildDebt(principalMinor: 10000),
        entries: [
          buildEntry(kind: DebtEntryKind.manualAdjustment, amountMinor: -3000),
        ],
        cashEvents: const [],
      );

      expect(up.outstandingMinor, 12000);
      expect(down.outstandingMinor, 7000);
    });
  });

  group('clamp to 0 and settled', () {
    test('over-payment clamps the shown balance and flags settled + excess', () {
      final balance = calc.calculate(
        debt: buildDebt(principalMinor: 10000),
        entries: const [],
        cashEvents: [
          buildCashEvent(type: TransactionType.expense, amountMinor: 13000),
        ],
      );

      expect(balance.rawOutstandingMinor, -3000);
      expect(balance.outstandingMinor, 0);
      expect(balance.settled, isTrue);
      expect(balance.excessMinor, 3000);
    });

    test('exactly 0 is settled with no excess', () {
      final balance = calc.calculate(
        debt: buildDebt(principalMinor: 10000),
        entries: const [],
        cashEvents: [
          buildCashEvent(type: TransactionType.expense, amountMinor: 10000),
        ],
      );

      expect(balance.settled, isTrue);
      expect(balance.excessMinor, 0);
      expect(balance.progress, 1.0);
    });

    test('a negative principal is clamped to 0 defensively', () {
      final balance = calc.calculate(
        debt: buildDebt(principalMinor: -5000),
        entries: const [],
        cashEvents: const [],
      );

      expect(balance.principalMinor, 0);
      expect(balance.outstandingMinor, 0);
    });
  });

  group('progress', () {
    test('is paid / total', () {
      final balance = calc.calculate(
        debt: buildDebt(principalMinor: 100000),
        entries: const [],
        cashEvents: [
          buildCashEvent(type: TransactionType.expense, amountMinor: 25000),
        ],
      );

      expect(balance.progress, 0.25);
    });

    test('a debt with nothing owed reads full progress and is settled', () {
      final balance = calc.calculate(
        debt: buildDebt(principalMinor: 0),
        entries: const [],
        cashEvents: const [],
      );

      expect(balance.settled, isTrue); // 0 owed
      expect(balance.progress, 1.0);
    });
  });

  group('buildLedger', () {
    test('synthesizes an opening row and sorts newest first', () {
      final debt = buildDebt(
        principalMinor: 100000,
        createdAt: DateTime(2026, 1, 1),
      );
      final ledger = calc.buildLedger(
        debt: debt,
        entries: [
          buildEntry(
            id: 'e1',
            kind: DebtEntryKind.interestAccrual,
            amountMinor: 500,
            entryDate: DateTime(2026, 2, 15),
          ),
        ],
        cashEvents: [
          buildCashEvent(
            transactionId: 't1',
            type: TransactionType.expense,
            amountMinor: 20000,
            date: DateTime(2026, 3, 1),
          ),
        ],
      );

      expect(ledger.length, 3);
      // newest first: cash abono (mar) > interest (feb) > opening (jan)
      expect(ledger[0].transactionId, 't1');
      expect(ledger[0].kind, DebtLedgerKind.cashPayment);
      expect(ledger[0].effectMinor, -20000);
      expect(ledger[1].kind, DebtLedgerKind.interestAccrual);
      expect(ledger[2].kind, DebtLedgerKind.opening);
      expect(ledger[2].effectMinor, 100000);
    });

    test('omits the opening row when the principal is 0', () {
      final ledger = calc.buildLedger(
        debt: buildDebt(principalMinor: 0),
        entries: const [],
        cashEvents: const [],
      );

      expect(ledger, isEmpty);
    });
  });
}
