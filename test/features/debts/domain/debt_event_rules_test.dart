import 'package:billetudo/features/debts/domain/entities/debt.dart';
import 'package:billetudo/features/debts/domain/entities/debt_cash_event.dart';
import 'package:billetudo/features/debts/domain/services/debt_event_rules.dart';
import 'package:billetudo/features/transactions/domain/entities/transaction.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('cashEventEffect', () {
    test('encodes the full direction × type table', () {
      expect(
        DebtEventRules.cashEventEffect(
          direction: DebtDirection.iOwe,
          type: TransactionType.income,
          amountMinor: 100,
        ),
        100,
      );
      expect(
        DebtEventRules.cashEventEffect(
          direction: DebtDirection.iOwe,
          type: TransactionType.expense,
          amountMinor: 100,
        ),
        -100,
      );
      expect(
        DebtEventRules.cashEventEffect(
          direction: DebtDirection.owedToMe,
          type: TransactionType.expense,
          amountMinor: 100,
        ),
        100,
      );
      expect(
        DebtEventRules.cashEventEffect(
          direction: DebtDirection.owedToMe,
          type: TransactionType.income,
          amountMinor: 100,
        ),
        -100,
      );
    });

    test('a transfer contributes 0', () {
      expect(
        DebtEventRules.cashEventEffect(
          direction: DebtDirection.iOwe,
          type: TransactionType.transfer,
          amountMinor: 100,
        ),
        0,
      );
    });
  });

  group('cashEventType', () {
    test('resolves the concrete income/expense per direction', () {
      expect(
        DebtEventRules.cashEventType(
          direction: DebtDirection.iOwe,
          kind: DebtCashEventKind.disbursement,
        ),
        TransactionType.income,
      );
      expect(
        DebtEventRules.cashEventType(
          direction: DebtDirection.iOwe,
          kind: DebtCashEventKind.payment,
        ),
        TransactionType.expense,
      );
      expect(
        DebtEventRules.cashEventType(
          direction: DebtDirection.owedToMe,
          kind: DebtCashEventKind.disbursement,
        ),
        TransactionType.expense,
      );
      expect(
        DebtEventRules.cashEventType(
          direction: DebtDirection.owedToMe,
          kind: DebtCashEventKind.payment,
        ),
        TransactionType.income,
      );
    });
  });

  group('countsInBudgetFor', () {
    test(
        'owedToMe + income (a repago recibido) counts in budget, raising '
        'the disponible', () {
      expect(
        DebtEventRules.countsInBudgetFor(
          direction: DebtDirection.owedToMe,
          type: TransactionType.income,
        ),
        isTrue,
      );
    });

    test('every other direction × type combination stays false', () {
      expect(
        DebtEventRules.countsInBudgetFor(
          direction: DebtDirection.iOwe,
          type: TransactionType.income,
        ),
        isFalse,
      );
      expect(
        DebtEventRules.countsInBudgetFor(
          direction: DebtDirection.iOwe,
          type: TransactionType.expense,
        ),
        isFalse,
      );
      expect(
        DebtEventRules.countsInBudgetFor(
          direction: DebtDirection.owedToMe,
          type: TransactionType.expense,
        ),
        isFalse,
      );
      expect(
        DebtEventRules.countsInBudgetFor(
          direction: DebtDirection.iOwe,
          type: TransactionType.transfer,
        ),
        isFalse,
      );
    });
  });

  group('ledgerEventAmount', () {
    test('disbursement is positive, payment is negative', () {
      expect(
        DebtEventRules.ledgerEventAmount(
          kind: DebtCashEventKind.disbursement,
          magnitudeMinor: 500,
        ),
        500,
      );
      expect(
        DebtEventRules.ledgerEventAmount(
          kind: DebtCashEventKind.payment,
          magnitudeMinor: 500,
        ),
        -500,
      );
    });
  });
}
