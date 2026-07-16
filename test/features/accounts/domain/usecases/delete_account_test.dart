import 'package:billetudo/core/error/result.dart';
import 'package:billetudo/features/accounts/domain/entities/account_deletion_impact.dart';
import 'package:billetudo/features/accounts/domain/usecases/delete_account.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'account_repository_mock.dart';

void main() {
  late MockAccountRepository repository;
  late DeleteAccount deleteAccount;

  setUp(() {
    repository = MockAccountRepository();
    deleteAccount = DeleteAccount(repository);
    when(() => repository.softDeleteAccount(any()))
        .thenAnswer((_) async => const Right(unit));
  });

  void givenImpact({
    int transactionCount = 0,
    int goalCount = 0,
    int debtCount = 0,
    bool isLastAccount = false,
  }) {
    when(() => repository.getDeletionImpact(any())).thenAnswer(
      (_) async => Right(
        AccountDeletionImpact(
          transactionCount: transactionCount,
          goalCount: goalCount,
          debtCount: debtCount,
          isLastAccount: isLastAccount,
        ),
      ),
    );
  }

  test('borra lógicamente una cuenta cuando no es la última', () async {
    givenImpact(transactionCount: 12);

    final result = await deleteAccount('acc-1');

    expect(result.isRight(), isTrue);
    verify(() => repository.softDeleteAccount('acc-1')).called(1);
  });

  test('HU-08: bloquea eliminar la única cuenta activa', () async {
    givenImpact(isLastAccount: true);

    final result = await deleteAccount('acc-1');

    final failure = result.getLeft().toNullable()! as ValidationFailure;
    expect(failure.field, DeleteAccount.lastAccountField);
    // La app siempre necesita una cuenta donde registrar: no se toca la BD.
    verifyNever(() => repository.softDeleteAccount(any()));
  });

  test('bloquea la última cuenta aunque no tenga transacciones', () async {
    givenImpact(isLastAccount: true);

    final result = await deleteAccount('acc-1');

    expect(result.isLeft(), isTrue);
  });

  test('consulta el impacto antes de borrar, nunca al revés', () async {
    givenImpact();

    await deleteAccount('acc-1');

    verifyInOrder([
      () => repository.getDeletionImpact('acc-1'),
      () => repository.softDeleteAccount('acc-1'),
    ]);
  });

  test('si no puede calcular el impacto, no borra', () async {
    when(() => repository.getDeletionImpact(any()))
        .thenAnswer((_) async => const Left(DatabaseFailure('sin disco')));

    final result = await deleteAccount('acc-1');

    expect(result.getLeft().toNullable(), isA<DatabaseFailure>());
    verifyNever(() => repository.softDeleteAccount(any()));
  });

  test('propaga el fallo del borrado', () async {
    givenImpact();
    when(() => repository.softDeleteAccount(any()))
        .thenAnswer((_) async => const Left(DatabaseFailure('sin disco')));

    final result = await deleteAccount('acc-1');

    expect(result.getLeft().toNullable(), isA<DatabaseFailure>());
  });
}
