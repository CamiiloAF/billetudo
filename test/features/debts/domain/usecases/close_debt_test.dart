import 'package:billetudo/core/error/result.dart';
import 'package:billetudo/features/debts/domain/usecases/close_debt.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../debt_test_fixtures.dart';
import 'debt_repository_mock.dart';

void main() {
  late MockDebtRepository repository;
  late CloseDebt usecase;

  setUp(() {
    repository = MockDebtRepository();
    usecase = CloseDebt(repository);
  });

  test('closes an open debt', () async {
    when(() => repository.getDebt('d1'))
        .thenAnswer((_) async => Right(buildDebt()));
    when(() => repository.closeDebt('d1'))
        .thenAnswer((_) async => const Right(unit));

    final result = await usecase('d1');

    expect(result.isRight(), isTrue);
    verify(() => repository.closeDebt('d1')).called(1);
  });

  test('fails with a ValidationFailure when the debt is already closed',
      () async {
    when(() => repository.getDebt('d1')).thenAnswer(
      (_) async => Right(buildDebt(closedAt: DateTime(2026, 6, 1))),
    );

    final result = await usecase('d1');

    final failure = result.getLeft().toNullable();
    expect(failure, isA<ValidationFailure>());
    expect((failure! as ValidationFailure).field, 'closedAt');
    verifyNever(() => repository.closeDebt(any()));
  });

  test('propagates a repository failure when the debt cannot be found',
      () async {
    when(() => repository.getDebt('missing')).thenAnswer(
      (_) async => const Left(NotFoundFailure('debt not found')),
    );

    final result = await usecase('missing');

    expect(result.getLeft().toNullable(), isA<NotFoundFailure>());
    verifyNever(() => repository.closeDebt(any()));
  });

  test(
      'never touches ScheduledPayments: `isActive` for a linked template is '
      'derived by reading `Debts.closedAt`, so closing a debt only calls '
      'getDebt + closeDebt on the debt repository and nothing else — '
      'reintroducing a cross-feature write here would duplicate what the '
      "scheduled_payments repository's `_activeExpr` already resolves by "
      'itself', () async {
    when(() => repository.getDebt('d1'))
        .thenAnswer((_) async => Right(buildDebt()));
    when(() => repository.closeDebt('d1'))
        .thenAnswer((_) async => const Right(unit));

    final result = await usecase('d1');

    expect(result.isRight(), isTrue);
    verify(() => repository.getDebt('d1')).called(1);
    verify(() => repository.closeDebt('d1')).called(1);
    // `DebtRepository`'s contract has no method that could write to
    // `ScheduledPayments` (see `debt_repository.dart`); this pins the
    // interaction count so a future change that adds one is caught here.
    verifyNoMoreInteractions(repository);
  });
}
