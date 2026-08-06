import 'package:billetudo/core/error/result.dart';
import 'package:billetudo/features/debts/domain/usecases/link_transaction_to_debt.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../debt_test_fixtures.dart';
import 'debt_repository_mock.dart';

// budget-income-counts-in-budget (criterion 3): whether linking forces
// countsInBudget = true is a repository-level decision (see
// `DebtRepository.linkTransactionToDebt`'s doc) — the repository reads both
// the debt and the transaction to decide, neither of which this use case's
// signature carries. That behaviour is covered end-to-end against a real
// in-memory Drift db in
// `test/features/debts/data/repositories/debt_repository_impl_test.dart`.
// This use case's own contract stays the same: validate ids, reject a
// closed debt, delegate.
void main() {
  late MockDebtRepository repository;
  late LinkTransactionToDebt usecase;

  setUp(() {
    repository = MockDebtRepository();
    usecase = LinkTransactionToDebt(repository);
  });

  test('delegates the debtId attribution to the repository', () async {
    when(() => repository.getDebt('d1'))
        .thenAnswer((_) async => Right(buildDebt()));
    when(
      () => repository.linkTransactionToDebt(
        transactionId: 't1',
        debtId: 'd1',
      ),
    ).thenAnswer((_) async => const Right(unit));

    final result = await usecase(transactionId: 't1', debtId: 'd1');

    expect(result.isRight(), isTrue);
    verify(
      () => repository.linkTransactionToDebt(transactionId: 't1', debtId: 'd1'),
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

  test('rejects linking a transaction to a closed debt', () async {
    when(() => repository.getDebt('d1')).thenAnswer(
      (_) async => Right(buildDebt(closedAt: DateTime(2026, 6, 1))),
    );

    final result = await usecase(transactionId: 't1', debtId: 'd1');

    final failure = result.getLeft().toNullable();
    expect(failure, isA<ValidationFailure>());
    expect((failure! as ValidationFailure).field, 'closedAt');
    verifyNever(
      () => repository.linkTransactionToDebt(
        transactionId: any(named: 'transactionId'),
        debtId: any(named: 'debtId'),
      ),
    );
  });
}
