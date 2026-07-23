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
    DateTime? startDate,
    DateTime? dueDate,
  }) =>
      DebtDraft(
        name: name,
        direction: DebtDirection.iOwe,
        principalMinor: principalMinor,
        currency: currency,
        counterparty: counterparty,
        interestRateBps: interestRateBps,
        startDate: startDate,
        dueDate: dueDate,
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

  test('rejects a zero opening balance', () {
    final result = draft(principalMinor: 0).validated();
    expect(
      (result.getLeft().toNullable()! as ValidationFailure).field,
      DebtDraft.fieldPrincipalMinor,
    );
  });

  test('rejects a negative opening balance', () {
    final result = draft(principalMinor: -1).validated();
    expect(
      (result.getLeft().toNullable()! as ValidationFailure).field,
      DebtDraft.fieldPrincipalMinor,
    );
  });

  test('rejects a due date equal to the start date', () {
    final result = draft(
      startDate: DateTime(2025, 6, 15),
      dueDate: DateTime(2025, 6, 15, 23, 59),
    ).validated();
    expect(
      (result.getLeft().toNullable()! as ValidationFailure).field,
      DebtDraft.fieldDueDate,
    );
  });

  test('rejects a due date before the start date', () {
    final result = draft(
      startDate: DateTime(2025, 6, 15),
      dueDate: DateTime(2025, 6, 14),
    ).validated();
    expect(
      (result.getLeft().toNullable()! as ValidationFailure).field,
      DebtDraft.fieldDueDate,
    );
  });

  test('accepts a due date after the start date', () {
    final result = draft(
      startDate: DateTime(2025, 6, 15),
      dueDate: DateTime(2025, 6, 16),
    ).validated();
    expect(result.isRight(), isTrue);
  });

  test('accepts a null due date (Sin fecha)', () {
    expect(
      draft(startDate: DateTime(2025, 6, 15)).validated().isRight(),
      isTrue,
    );
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

  test('rejects a start date in the future', () {
    final tomorrow = DateTime.now().add(const Duration(days: 1));
    final result = draft(startDate: tomorrow).validated();
    expect(
      (result.getLeft().toNullable()! as ValidationFailure).field,
      DebtDraft.fieldStartDate,
    );
  });

  test('accepts today as a start date', () {
    expect(draft(startDate: DateTime.now()).validated().isRight(), isTrue);
  });

  test('accepts a past start date and carries it through', () {
    final past = DateTime(2025, 1, 1);
    final value = draft(startDate: past).validated().getRight().toNullable()!;
    expect(value.startDate, past);
  });
}
