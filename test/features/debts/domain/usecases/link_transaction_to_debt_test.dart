import 'package:billetudo/core/error/result.dart';
import 'package:billetudo/features/debts/domain/usecases/link_transaction_to_debt.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'debt_repository_mock.dart';

void main() {
  late MockDebtRepository repository;
  late LinkTransactionToDebt usecase;

  setUp(() {
    repository = MockDebtRepository();
    usecase = LinkTransactionToDebt(repository);
  });

  test('delegates the debtId attribution to the repository', () async {
    when(
      () => repository.linkTransactionToDebt(
        transactionId: 't1',
        debtId: 'd1',
      ),
    ).thenAnswer((_) async => const Right(unit));

    final result = await usecase(transactionId: 't1', debtId: 'd1');

    expect(result.isRight(), isTrue);
    verify(
      () =>
          repository.linkTransactionToDebt(transactionId: 't1', debtId: 'd1'),
    ).called(1);
  });

  test('rejects a blank transaction id', () async {
    final result = await usecase(transactionId: '  ', debtId: 'd1');

    expect(result.getLeft().toNullable(), isA<ValidationFailure>());
    verifyNever(
      () => repository.linkTransactionToDebt(
        transactionId: any(named: 'transactionId'),
        debtId: any(named: 'debtId'),
      ),
    );
  });
}
