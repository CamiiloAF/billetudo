import 'package:billetudo/core/error/result.dart';
import 'package:billetudo/features/debts/domain/entities/debt.dart';
import 'package:billetudo/features/debts/domain/entities/debt_draft.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  DebtDraft draft({
    String name = 'Deuda',
    int principalMinor = 1000,
    String currency = 'COP',
    String? counterparty,
    int? interestRateBps,
  }) =>
      DebtDraft(
        name: name,
        direction: DebtDirection.iOwe,
        principalMinor: principalMinor,
        currency: currency,
        counterparty: counterparty,
        interestRateBps: interestRateBps,
      );

  test('normalizes name, currency and blank counterparty', () {
    final result = draft(
      name: '  Préstamo primo  ',
      currency: 'usd',
      counterparty: '   ',
    ).validated();

    final value = result.getRight().toNullable()!;
    expect(value.name, 'Préstamo primo');
    expect(value.currency, 'USD');
    expect(value.counterparty, isNull);
  });

  test('accepts a zero opening balance (built from the ledger)', () {
    expect(draft(principalMinor: 0).validated().isRight(), isTrue);
  });

  test('rejects a non-ISO currency', () {
    final result = draft(currency: 'PESOS').validated();
    expect(
      (result.getLeft().toNullable()! as ValidationFailure).field,
      DebtDraft.fieldCurrency,
    );
  });

  test('rejects a negative interest rate', () {
    final result = draft(interestRateBps: -1).validated();
    expect(
      (result.getLeft().toNullable()! as ValidationFailure).field,
      DebtDraft.fieldInterestRateBps,
    );
  });
}
