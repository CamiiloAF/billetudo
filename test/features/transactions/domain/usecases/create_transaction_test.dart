import 'package:billetudo/core/error/result.dart';
import 'package:billetudo/features/categories/domain/entities/category.dart'
    show CategoryKind;
import 'package:billetudo/features/transactions/domain/entities/transaction.dart';
import 'package:billetudo/features/transactions/domain/entities/transaction_draft.dart';
import 'package:billetudo/features/transactions/domain/usecases/create_transaction.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../transaction_fixtures.dart';
import 'transaction_repository_mock.dart';

void main() {
  late MockTransactionRepository repository;
  late CreateTransaction createTransaction;

  setUpAll(registerTransactionFallbacks);

  setUp(() {
    repository = MockTransactionRepository();
    createTransaction = CreateTransaction(repository);
    when(() => repository.createTransaction(any())).thenAnswer(
      (invocation) async => Right(
        buildTransaction(
          accountId: (invocation.positionalArguments.first as TransactionDraft)
              .accountId,
        ),
      ),
    );
  });

  TransactionDraft capturedDraft() =>
      verify(() => repository.createTransaction(captureAny())).captured.single
          as TransactionDraft;

  test('HU-01: persiste un gasto válido y no toca la categoría si no hay una',
      () async {
    final result = await createTransaction(buildExpenseDraft());

    expect(result.isRight(), isTrue);
    final draft = capturedDraft();
    expect(draft.type, TransactionType.expense);
    expect(draft.source, TransactionSource.manual);
  });

  test('HU-01: rechaza un gasto sin cuenta antes de llegar al repositorio',
      () async {
    final result = await createTransaction(buildExpenseDraft(accountId: ''));

    expect(result.isLeft(), isTrue);
    verifyNever(() => repository.createTransaction(any()));
  });

  test('HU-01: rechaza una categoría de kind income en un gasto', () async {
    final result = await createTransaction(
      buildExpenseDraft(categoryId: 'cat-1', categoryKind: CategoryKind.income),
    );

    expect(
      (result.getLeft().toNullable()! as ValidationFailure).field,
      TransactionDraft.fieldCategoryId,
    );
    verifyNever(() => repository.createTransaction(any()));
  });

  test('HU-02: persiste un ingreso válido', () async {
    final result = await createTransaction(
      buildIncomeDraft(categoryId: 'cat-2', categoryKind: CategoryKind.income),
    );

    expect(result.isRight(), isTrue);
    expect(capturedDraft().type, TransactionType.income);
  });

  test('HU-03: persiste una transferencia sin categoría', () async {
    final result = await createTransaction(buildTransferDraft());

    expect(result.isRight(), isTrue);
    final draft = capturedDraft();
    expect(draft.type, TransactionType.transfer);
    expect(draft.categoryId, isNull);
    expect(draft.transferAccountId, isNotNull);
  });

  test('HU-03: rechaza una transferencia con cuentas origen/destino iguales',
      () async {
    final result = await createTransaction(
      buildTransferDraft(transferAccountId: 'acc-1'),
    );

    expect(result.isLeft(), isTrue);
    verifyNever(() => repository.createTransaction(any()));
  });

  test('propaga el fallo del repositorio sin envolverlo', () async {
    when(() => repository.createTransaction(any())).thenAnswer(
      (_) async => const Left(DatabaseFailure('disco lleno')),
    );

    final result = await createTransaction(buildExpenseDraft());

    expect(result.getLeft().toNullable(), isA<DatabaseFailure>());
  });
}
