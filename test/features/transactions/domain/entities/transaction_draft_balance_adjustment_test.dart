import 'package:billetudo/features/transactions/domain/entities/transaction.dart';
import 'package:billetudo/features/transactions/domain/entities/transaction_draft.dart';
import 'package:flutter_test/flutter_test.dart';

/// Mejora #1: a balance reconciliation is a category-less income/expense. The
/// flag relaxes the mandatory-category rule only for it; a normal draft still
/// requires a category.
void main() {
  TransactionDraft draft({
    required TransactionType type,
    String? categoryId,
    bool isBalanceAdjustment = false,
  }) =>
      TransactionDraft(
        accountId: 'acc-1',
        amountMinor: 50000,
        currency: 'COP',
        type: type,
        date: DateTime(2026, 7, 21),
        categoryId: categoryId,
        isBalanceAdjustment: isBalanceAdjustment,
      );

  test('un ingreso de ajuste sin categoría pasa la validación', () {
    final result =
        draft(type: TransactionType.income, isBalanceAdjustment: true)
            .validated();

    expect(result.isRight(), isTrue);
    final normalized = result.getRight().toNullable()!;
    expect(normalized.categoryId, isNull);
    expect(normalized.isBalanceAdjustment, isTrue);
  });

  test('un gasto de ajuste sin categoría pasa la validación', () {
    final result =
        draft(type: TransactionType.expense, isBalanceAdjustment: true)
            .validated();

    expect(result.isRight(), isTrue);
    expect(result.getRight().toNullable()!.isBalanceAdjustment, isTrue);
  });

  test('sin la marca, un ingreso sin categoría sigue siendo rechazado', () {
    final result = draft(type: TransactionType.income).validated();

    expect(result.isLeft(), isTrue);
  });
}
