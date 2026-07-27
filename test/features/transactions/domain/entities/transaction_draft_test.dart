import 'package:billetudo/core/error/result.dart';
import 'package:billetudo/features/categories/domain/entities/category.dart'
    show CategoryKind;
import 'package:billetudo/features/transactions/domain/entities/transaction.dart';
import 'package:billetudo/features/transactions/domain/entities/transaction_draft.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../transaction_fixtures.dart';

void main() {
  ValidationFailure failureOf(Result<TransactionDraft> result) =>
      result.getLeft().toNullable()! as ValidationFailure;

  group('HU-01 — gasto', () {
    test('un gasto válido con solo los campos obligatorios pasa', () {
      final result = buildExpenseDraft().validated();

      expect(result.isRight(), isTrue);
      final draft = result.getRight().toNullable()!;
      expect(draft.type, TransactionType.expense);
      expect(draft.source, TransactionSource.manual);
      expect(draft.transferAccountId, isNull);
    });

    test('rechaza una cuenta vacía', () {
      final result = buildExpenseDraft(accountId: '   ').validated();

      expect(failureOf(result).field, TransactionDraft.fieldAccountId);
    });

    test('rechaza un monto cero o negativo', () {
      for (final amount in [0, -1, -1000]) {
        final result = buildExpenseDraft(amountMinor: amount).validated();

        expect(failureOf(result).field, TransactionDraft.fieldAmountMinor);
      }
    });

    test('rechaza una categoría de kind income en un gasto', () {
      final result = buildExpenseDraft(
        categoryId: 'cat-income',
        categoryKind: CategoryKind.income,
      ).validated();

      expect(failureOf(result).field, TransactionDraft.fieldCategoryId);
    });

    test('acepta una categoría de kind expense en un gasto', () {
      final result = buildExpenseDraft(categoryId: 'cat-expense').validated();

      expect(result.isRight(), isTrue);
      expect(result.getRight().toNullable()!.categoryId, 'cat-expense');
    });

    test('rechaza un gasto sin categoría', () {
      final result = buildExpenseDraft(categoryId: null).validated();

      expect(failureOf(result).field, TransactionDraft.fieldCategoryId);
    });

    test('normaliza la moneda a mayúsculas', () {
      final result = buildExpenseDraft(currency: 'cop').validated();

      expect(result.getRight().toNullable()!.currency, 'COP');
    });

    test('rechaza una moneda que no es un código ISO-4217 de 3 letras', () {
      for (final currency in ['', 'CO', 'COPS', '123']) {
        final result = buildExpenseDraft(currency: currency).validated();

        expect(failureOf(result).field, TransactionDraft.fieldCurrency);
      }
    });

    test('recorta espacios de la nota y vacía la deja en null', () {
      final result = buildExpenseDraft(note: '  ').validated();
      expect(result.getRight().toNullable()!.note, isNull);

      final withNote = buildExpenseDraft(note: '  café  ').validated();
      expect(withNote.getRight().toNullable()!.note, 'café');
    });

    test('rechaza una nota demasiado larga', () {
      final result =
          buildExpenseDraft(note: 'a' * (TransactionDraft.maxNoteLength + 1))
              .validated();

      expect(failureOf(result).field, TransactionDraft.fieldNote);
    });

    test('el monto viaja como entero de centavos', () {
      final result = buildExpenseDraft(amountMinor: 123456).validated();

      final draft = result.getRight().toNullable()!;
      expect(draft.amountMinor, 123456);
      expect(draft.amountMinor, isA<int>());
    });
  });

  group('HU-02 — ingreso', () {
    test('rechaza una categoría de kind expense en un ingreso', () {
      final result = buildIncomeDraft(
        categoryId: 'cat-expense',
        categoryKind: CategoryKind.expense,
      ).validated();

      expect(failureOf(result).field, TransactionDraft.fieldCategoryId);
    });

    test('acepta una categoría de kind income en un ingreso', () {
      final result = buildIncomeDraft(categoryId: 'cat-income').validated();

      expect(result.isRight(), isTrue);
    });

    test('rechaza un ingreso sin categoría', () {
      final result = buildIncomeDraft(categoryId: null).validated();

      expect(failureOf(result).field, TransactionDraft.fieldCategoryId);
    });
  });

  group('HU-03 — transferencia', () {
    test('exige cuenta destino', () {
      final result = buildTransferDraft(transferAccountId: null).validated();

      expect(failureOf(result).field, TransactionDraft.fieldTransferAccountId);
    });

    test('rechaza cuenta origen y destino iguales', () {
      final result = buildTransferDraft(transferAccountId: 'acc-1').validated();

      expect(failureOf(result).field, TransactionDraft.fieldTransferAccountId);
    });

    test('una transferencia nunca lleva categoría', () {
      final result = buildTransferDraft().validated();

      final draft = result.getRight().toNullable()!;
      expect(draft.categoryId, isNull);
      expect(draft.type, TransactionType.transfer);
    });

    test('una transferencia válida pasa', () {
      final result = buildTransferDraft().validated();

      expect(result.isRight(), isTrue);
    });
  });

  group('B-3 — transferencia presupuestable (countsInBudget)', () {
    test(
        'countsInBudget=false (default) no exige categoría, incluso si se '
        'pasa una', () {
      final result = buildTransferDraft(
        categoryId: 'cat-expense',
        categoryKind: CategoryKind.expense,
      ).validated();

      expect(result.isRight(), isTrue);
      final draft = result.getRight().toNullable()!;
      // The default flow drops any category even if one was set: a plain
      // transfer never carries one (HU-03).
      expect(draft.categoryId, isNull);
      expect(draft.countsInBudget, isFalse);
    });

    test('countsInBudget=true sin categoría falla', () {
      final result = buildTransferDraft(countsInBudget: true).validated();

      expect(failureOf(result).field, TransactionDraft.fieldCategoryId);
    });

    test(
        'countsInBudget=true con categoría de kind expense pasa y conserva '
        'el flag', () {
      final result = buildTransferDraft(
        countsInBudget: true,
        categoryId: 'cat-expense',
        categoryKind: CategoryKind.expense,
      ).validated();

      expect(result.isRight(), isTrue);
      final draft = result.getRight().toNullable()!;
      expect(draft.categoryId, 'cat-expense');
      expect(draft.countsInBudget, isTrue);
    });

    test('countsInBudget=true con categoría de kind income falla', () {
      final result = buildTransferDraft(
        countsInBudget: true,
        categoryId: 'cat-income',
        categoryKind: CategoryKind.income,
      ).validated();

      expect(failureOf(result).field, TransactionDraft.fieldCategoryId);
    });

    test(
        'un gasto o ingreso con countsInBudget=true en el input se '
        'normaliza a false (el flag solo aplica a transferencias)', () {
      final expenseResult = TransactionDraft(
        accountId: 'acc-1',
        categoryId: 'cat-expense-1',
        categoryKind: CategoryKind.expense,
        amountMinor: 10000,
        currency: 'COP',
        type: TransactionType.expense,
        date: testInstant,
        countsInBudget: true,
      ).validated();

      expect(expenseResult.isRight(), isTrue);
      expect(expenseResult.getRight().toNullable()!.countsInBudget, isFalse);
    });
  });
}
