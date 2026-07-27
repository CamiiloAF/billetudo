import 'package:billetudo/core/error/result.dart';
import 'package:billetudo/features/debts/domain/usecases/delete_debt.dart';
import 'package:billetudo/features/debts/domain/usecases/restore_debt.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'debt_repository_mock.dart';

void main() {
  late MockDebtRepository repository;

  setUp(() => repository = MockDebtRepository());

  test('DeleteDebt delegates the soft delete to the repository', () async {
    when(() => repository.deleteDebt('d1'))
        .thenAnswer((_) async => const Right(unit));

    final result = await DeleteDebt(repository)('d1');

    expect(result.isRight(), isTrue);
    verify(() => repository.deleteDebt('d1')).called(1);
  });

  test('RestoreDebt delegates the undo to the repository', () async {
    when(() => repository.restoreDebt('d1'))
        .thenAnswer((_) async => const Right(unit));

    final result = await RestoreDebt(repository)('d1');

    expect(result.isRight(), isTrue);
    verify(() => repository.restoreDebt('d1')).called(1);
  });
}
