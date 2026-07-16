import 'package:billetudo/core/error/result.dart';
import 'package:billetudo/features/accounts/domain/entities/account_deletion_impact.dart';
import 'package:billetudo/features/accounts/domain/usecases/get_account_deletion_impact.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'account_repository_mock.dart';

void main() {
  late MockAccountRepository repository;
  late GetAccountDeletionImpact getImpact;

  setUp(() {
    repository = MockAccountRepository();
    getImpact = GetAccountDeletionImpact(repository);
  });

  test('HU-08: reporta el conteo de transacciones, metas y deudas', () async {
    when(() => repository.getDeletionImpact('acc-1')).thenAnswer(
      (_) async => const Right(
        AccountDeletionImpact(
          transactionCount: 12,
          goalCount: 2,
          debtCount: 1,
          isLastAccount: false,
        ),
      ),
    );

    final result = await getImpact('acc-1');

    final impact = result.getRight().toNullable()!;
    expect(impact.transactionCount, 12);
    expect(impact.goalCount, 2);
    expect(impact.debtCount, 1);
    expect(impact.hasImpact, isTrue);
    expect(impact.isLastAccount, isFalse);
  });

  test('una cuenta recién creada no tiene impacto que advertir', () async {
    when(() => repository.getDeletionImpact('acc-1')).thenAnswer(
      (_) async => const Right(
        AccountDeletionImpact(
          transactionCount: 0,
          goalCount: 0,
          debtCount: 0,
          isLastAccount: false,
        ),
      ),
    );

    final result = await getImpact('acc-1');

    expect(result.getRight().toNullable()!.hasImpact, isFalse);
  });

  test('hasImpact es cierto si solo hay metas asociadas', () {
    const impact = AccountDeletionImpact(
      transactionCount: 0,
      goalCount: 1,
      debtCount: 0,
      isLastAccount: false,
    );

    expect(impact.hasImpact, isTrue);
  });

  test('propaga el fallo del repositorio', () async {
    when(() => repository.getDeletionImpact(any()))
        .thenAnswer((_) async => const Left(DatabaseFailure('sin disco')));

    final result = await getImpact('acc-1');

    expect(result.getLeft().toNullable(), isA<DatabaseFailure>());
  });
}
