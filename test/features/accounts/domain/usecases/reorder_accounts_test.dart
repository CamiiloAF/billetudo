import 'package:billetudo/core/error/result.dart';
import 'package:billetudo/features/accounts/domain/usecases/reorder_accounts.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'account_repository_mock.dart';

void main() {
  late MockAccountRepository repository;
  late ReorderAccounts reorderAccounts;

  setUp(() {
    repository = MockAccountRepository();
    reorderAccounts = ReorderAccounts(repository);
    when(() => repository.reorderAccounts(any()))
        .thenAnswer((_) async => const Right(unit));
  });

  test('HU-09: entrega el orden final al repositorio tal cual', () async {
    final result = await reorderAccounts(['b', 'c', 'a']);

    expect(result.isRight(), isTrue);
    verify(() => repository.reorderAccounts(['b', 'c', 'a'])).called(1);
  });

  test('rechaza un orden con ids repetidos', () async {
    final result = await reorderAccounts(['a', 'b', 'a']);

    final failure = result.getLeft().toNullable()! as ValidationFailure;
    expect(failure.field, ReorderAccounts.orderedIdsField);
    verifyNever(() => repository.reorderAccounts(any()));
  });

  test('una lista vacía es un no-op válido', () async {
    final result = await reorderAccounts([]);

    expect(result.isRight(), isTrue);
  });

  test('propaga el fallo del repositorio', () async {
    when(() => repository.reorderAccounts(any()))
        .thenAnswer((_) async => const Left(DatabaseFailure('sin disco')));

    final result = await reorderAccounts(['a']);

    expect(result.getLeft().toNullable(), isA<DatabaseFailure>());
  });
}
