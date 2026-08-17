import 'package:billetudo/core/error/result.dart';
import 'package:billetudo/features/debts/domain/usecases/delete_debt_entry.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'debt_repository_mock.dart';

void main() {
  late MockDebtRepository repository;

  setUp(() => repository = MockDebtRepository());

  test('delegates the soft delete to the repository', () async {
    when(() => repository.deleteDebtEntry('e1'))
        .thenAnswer((_) async => const Right(unit));

    final result = await DeleteDebtEntry(repository)('e1');

    expect(result.isRight(), isTrue);
    verify(() => repository.deleteDebtEntry('e1')).called(1);
  });

  test('propagates a repository failure', () async {
    when(() => repository.deleteDebtEntry('missing')).thenAnswer(
      (_) async => const Left(NotFoundFailure('debt entry not found')),
    );

    final result = await DeleteDebtEntry(repository)('missing');

    expect(result.isLeft(), isTrue);
  });
}
