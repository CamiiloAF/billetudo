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

  group('displayTotalMinor (reconciliation resets the "de \$X" denominator)', () {
    test('with no manualAdjustment, falls back to the full historical total',
        () {
      final balance = calc.calculate(
        debt: buildDebt(
          principalMinor: 98000000,
          createdAt: DateTime(2026, 1, 1),
          startDate: DateTime(2026, 1, 1),
        ),
        entries: const [],
        cashEvents: [
          buildCashEvent(
            type: TransactionType.expense,
            amountMinor: 2000000,
            date: DateTime(2026, 2, 1),
          ),
        ],
      );

      expect(balance.totalIncreasesMinor, 98000000);
      expect(balance.displayTotalMinor, balance.totalIncreasesMinor);
    });

    test(
      'reconciling to \$110M with \$2M already abonado shows "de \$110M", '
      'not "de \$112M"',
      () {
        // Reproduces the reported bug: opening 98M, a 2M abono before the
        // user reconciles to 110M via UpdateDebtBalance. Raw outstanding was
        // 96M, so the diff written is +14M -> totalIncreasesMinor (historical)
        // becomes 112M, but the shown denominator must read the reconciled
        // figure itself: 110M.
        final debt = buildDebt(
          principalMinor: 98000000,
          createdAt: DateTime(2026, 1, 1),
          startDate: DateTime(2026, 1, 1),
        );
        final balance = calc.calculate(
          debt: debt,
          entries: [
            buildEntry(
              id: 'reconciliation',
              kind: DebtEntryKind.manualAdjustment,
              amountMinor: 14000000,
              entryDate: DateTime(2026, 3, 1),
            ),
          ],
          cashEvents: [
            buildCashEvent(
              transactionId: 't-abono',
              type: TransactionType.expense,
              amountMinor: 2000000,
              date: DateTime(2026, 2, 1),
            ),
          ],
        );

        expect(balance.totalIncreasesMinor, 112000000); // historical, unfixed
        expect(balance.outstandingMinor, 110000000); // already correct today
        expect(balance.displayTotalMinor, 110000000); // the fix
      },
    );

    test(
      'a disbursement/interest posted after the reconciliation is added on '
      'top of the reconciled figure',
      () {
        final debt = buildDebt(
          principalMinor: 100000000,
          createdAt: DateTime(2026, 1, 1),
          startDate: DateTime(2026, 1, 1),
        );
        final balance = calc.calculate(
          debt: debt,
          entries: [
            buildEntry(
              id: 'reconciliation',
              kind: DebtEntryKind.manualAdjustment,
              amountMinor: -20000000, // reconciles down to 80M
              entryDate: DateTime(2026, 3, 1),
            ),
            buildEntry(
              id: 'interest-after',
              kind: DebtEntryKind.interestAccrual,
              amountMinor: 500000,
              entryDate: DateTime(2026, 4, 1),
            ),
          ],
          cashEvents: const [],
        );

        expect(balance.displayTotalMinor, 80500000);
        expect(balance.outstandingMinor, 80500000);
      },
    );

    test('a decrease after the reconciliation does not change the total', () {
      final debt = buildDebt(
        principalMinor: 100000000,
        createdAt: DateTime(2026, 1, 1),
        startDate: DateTime(2026, 1, 1),
      );
      final balance = calc.calculate(
        debt: debt,
        entries: [
          buildEntry(
            id: 'reconciliation',
            kind: DebtEntryKind.manualAdjustment,
            amountMinor: 10000000, // reconciles up to 110M
            entryDate: DateTime(2026, 3, 1),
          ),
          buildEntry(
            id: 'abono-after',
            kind: DebtEntryKind.payment,
            amountMinor: -5000000,
            entryDate: DateTime(2026, 4, 1),
          ),
        ],
        cashEvents: const [],
      );

      expect(balance.displayTotalMinor, 110000000);
      expect(balance.outstandingMinor, 105000000);
    });

    test('the most recent of two reconciliations wins', () {
      final debt = buildDebt(
        principalMinor: 100000000,
        createdAt: DateTime(2026, 1, 1),
        startDate: DateTime(2026, 1, 1),
      );
      final balance = calc.calculate(
        debt: debt,
        entries: [
          buildEntry(
            id: 'reconciliation-1',
            kind: DebtEntryKind.manualAdjustment,
            amountMinor: 10000000, // 100M -> 110M
            entryDate: DateTime(2026, 2, 1),
          ),
          buildEntry(
            id: 'reconciliation-2',
            kind: DebtEntryKind.manualAdjustment,
            amountMinor: -30000000, // 110M -> 80M
            entryDate: DateTime(2026, 3, 1),
          ),
        ],
        cashEvents: const [],
      );

      expect(balance.displayTotalMinor, 80000000);
    });

    test(
      'a deleted reconciliation is invisible: the calculator only ever sees '
      'active entries, so removing the manualAdjustment (Fix B) falls back to '
      'whatever remains — the previous reconciliation, or the full history',
      () {
        // The repository filters deletedAt before entries reach this
        // calculator, so there is nothing extra to wire here; this test just
        // documents the expectation for the "delete the reconciliation" edge
        // case named in the fix's dev-run.
        final debt = buildDebt(
          principalMinor: 100000000,
          createdAt: DateTime(2026, 1, 1),
          startDate: DateTime(2026, 1, 1),
        );
        final balance = calc.calculate(
          debt: debt,
          entries: const [], // as if the sole reconciliation was deleted
          cashEvents: const [],
        );

        expect(balance.displayTotalMinor, balance.totalIncreasesMinor);
      },
    );
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

    test(
      'the synthetic opening row is dated on the start date, not createdAt',
      () {
        // Solo-deuda: the opening figure is synthetic (no backing Transaction),
        // so its ledger date is derived. It must follow the debt's start date
        // (the "Fecha" the user picked), NOT `createdAt` (≈ today). This is the
        // device bug: a debt started in the past showed its "Saldo de apertura"
        // dated today, and editing "Fecha" never moved it.
        final debt = buildDebt(
          principalMinor: 100000,
          startDate: DateTime(2026, 2, 10),
          createdAt: DateTime(2026, 5, 30),
        );
        final ledger = calc.buildLedger(
          debt: debt,
          entries: const [],
          cashEvents: const [],
        );

        expect(ledger.single.kind, DebtLedgerKind.opening);
        expect(ledger.single.date, DateTime(2026, 2, 10));
        // createdAt stays the ordering key (unchanged).
        expect(ledger.single.createdAt, DateTime(2026, 5, 30));
      },
    );

    test(
      'the synthetic opening row falls back to createdAt when start date is null',
      () {
        // Legacy/unbackfilled rows carry a null startDate; effectiveStartDate
        // defends by falling back to createdAt.
        final debt = buildDebt(
          principalMinor: 100000,
          createdAt: DateTime(2026, 5, 30),
        );
        final ledger = calc.buildLedger(
          debt: debt,
          entries: const [],
          cashEvents: const [],
        );

        expect(ledger.single.kind, DebtLedgerKind.opening);
        expect(ledger.single.date, DateTime(2026, 5, 30));
      },
    );

    test(
      'same-day rows break ties by createdAt desc, sinking the opening to the '
      'bottom of its day',
      () {
        // Reproduces the device capture: opening +50k created first, then two
        // solo-deuda movements the SAME day, created afterwards. The event
        // dates all fall on the same day (date-picker values), so they tie on
        // `date` and createdAt breaks it — the opening must land at the bottom.
        final day = DateTime(2026, 7, 20);
        final debt = buildDebt(
          principalMinor: 50000,
          createdAt: day.add(const Duration(hours: 8)),
        );
        final ledger = calc.buildLedger(
          debt: debt,
          entries: [
            buildEntry(
              id: 'abono',
              kind: DebtEntryKind.payment,
              amountMinor: -10000,
              entryDate: day.add(const Duration(hours: 8)),
              createdAt: day.add(const Duration(hours: 9)),
            ),
            buildEntry(
              id: 'ajuste',
              kind: DebtEntryKind.manualAdjustment,
              amountMinor: 3000,
              entryDate: day.add(const Duration(hours: 8)),
              createdAt: day.add(const Duration(hours: 10)),
            ),
          ],
          cashEvents: const [],
        );

        expect(ledger.length, 3);
        // newest-created first within the day; opening (earliest createdAt) last
        expect(ledger[0].entryId, 'ajuste');
        expect(ledger[1].entryId, 'abono');
        expect(ledger[2].kind, DebtLedgerKind.opening);
        expect(ledger[2].effectMinor, 50000);
      },
    );

    test('same-day tie falls back to id when createdAt is identical', () {
      final day = DateTime(2026, 7, 20);
      final ledger = calc.buildLedger(
        debt: buildDebt(principalMinor: 0),
        entries: [
          buildEntry(
            id: 'bbb',
            amountMinor: 100,
            entryDate: day,
            createdAt: day,
          ),
          buildEntry(
            id: 'aaa',
            amountMinor: 200,
            entryDate: day,
            createdAt: day,
          ),
        ],
        cashEvents: const [],
      );

      expect(ledger.map((e) => e.entryId).toList(), ['aaa', 'bbb']);
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
