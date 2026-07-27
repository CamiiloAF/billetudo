import 'package:billetudo/features/transactions/domain/usecases/get_transaction_edit_impact.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../transaction_fixtures.dart';

void main() {
  const getImpact = GetTransactionEditImpact();

  test('HU-04: sin ningún link, editar nunca tiene impacto', () {
    final original = buildTransaction(amountMinor: 1000);
    final draft = buildExpenseDraft(id: original.id, amountMinor: 5000);

    final impact = getImpact(original: original, draft: draft);

    expect(impact.hasImpact, isFalse);
  });

  test(
      'HU-04: cambiar el monto de una transacción con scheduledPaymentId advierte',
      () {
    final original =
        buildTransaction(amountMinor: 1000, scheduledPaymentId: 'rec-1');
    final draft = buildExpenseDraft(id: original.id, amountMinor: 5000);

    final impact = getImpact(original: original, draft: draft);

    expect(impact.affectsScheduledPayment, isTrue);
    expect(impact.affectsGoal, isFalse);
    expect(impact.affectsDebt, isFalse);
  });

  test('HU-04: cambiar la cuenta de una transacción con goalId advierte', () {
    final original = buildTransaction(goalId: 'goal-1');
    final draft = buildExpenseDraft(
      id: original.id,
      accountId: 'acc-2',
      amountMinor: original.amountMinor,
    );

    final impact = getImpact(original: original, draft: draft);

    expect(impact.affectsGoal, isTrue);
  });

  test('HU-04: cambiar el monto de una transacción con debtId advierte', () {
    final original = buildTransaction(amountMinor: 1000, debtId: 'debt-1');
    final draft = buildExpenseDraft(id: original.id, amountMinor: 2000);

    final impact = getImpact(original: original, draft: draft);

    expect(impact.affectsDebt, isTrue);
  });

  test('HU-04: solo la nota no afecta ningún link', () {
    final original = buildTransaction(
      amountMinor: 1000,
      scheduledPaymentId: 'rec-1',
      goalId: 'goal-1',
      debtId: 'debt-1',
    );
    final draft = buildExpenseDraft(
      id: original.id,
      accountId: original.accountId,
      amountMinor: original.amountMinor,
      note: 'nota nueva',
    );

    final impact = getImpact(original: original, draft: draft);

    expect(impact.hasImpact, isFalse);
  });
}
