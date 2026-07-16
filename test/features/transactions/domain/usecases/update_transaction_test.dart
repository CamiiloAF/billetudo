import 'package:billetudo/core/error/result.dart';
import 'package:billetudo/features/transactions/domain/entities/transaction_draft.dart';
import 'package:billetudo/features/transactions/domain/usecases/update_transaction.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../transaction_fixtures.dart';
import 'transaction_repository_mock.dart';

void main() {
  late MockTransactionRepository repository;
  late UpdateTransaction updateTransaction;

  setUpAll(registerTransactionFallbacks);

  setUp(() {
    repository = MockTransactionRepository();
    updateTransaction = UpdateTransaction(repository);
    when(() => repository.updateTransaction(any())).thenAnswer(
      (invocation) async => Right(
        buildTransaction(
          id: (invocation.positionalArguments.first as TransactionDraft).id!,
        ),
      ),
    );
  });

  test('HU-04: edita un gasto válido y lo delega al repositorio', () async {
    final result = await updateTransaction(
      buildExpenseDraft(id: 'tx-1', amountMinor: 5000),
    );

    expect(result.isRight(), isTrue);
    verify(() => repository.updateTransaction(any())).called(1);
  });

  test('HU-04: la misma validación de HU-01/02/03 corre en la edición',
      () async {
    final result = await updateTransaction(
      buildExpenseDraft(id: 'tx-1', amountMinor: 0),
    );

    expect(
      (result.getLeft().toNullable()! as ValidationFailure).field,
      TransactionDraft.fieldAmountMinor,
    );
    verifyNever(() => repository.updateTransaction(any()));
  });

  test('propaga el fallo del repositorio sin envolverlo', () async {
    when(() => repository.updateTransaction(any())).thenAnswer(
      (_) async => const Left(NotFoundFailure('no existe')),
    );

    final result =
        await updateTransaction(buildExpenseDraft(id: 'tx-inexistente'));

    expect(result.getLeft().toNullable(), isA<NotFoundFailure>());
  });
}
