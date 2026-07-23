import 'package:billetudo/core/error/result.dart';
import 'package:billetudo/features/budgets/domain/usecases/cancel_budget_adjustment.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'budget_repository_mock.dart';

/// "Quitar ajuste": `CancelBudgetAdjustment` is a thin pass-through to
/// `BudgetRepository.cancelBudgetAdjustment`.
void main() {
  late MockBudgetRepository repository;
  late CancelBudgetAdjustment usecase;

  setUp(() {
    repository = MockBudgetRepository();
    usecase = CancelBudgetAdjustment(repository);
  });

  test('forwards the budget id', () async {
    when(() => repository.cancelBudgetAdjustment('b1',
            periodStart: DateTime(2026)))
        .thenAnswer((_) async => const Right(unit));

    final result = await usecase('b1', periodStart: DateTime(2026));

    expect(result.getRight().toNullable(), unit);
    verify(() => repository.cancelBudgetAdjustment('b1',
        periodStart: DateTime(2026))).called(1);
  });

  test('forwards a NotFoundFailure when there is no pending fork to cancel',
      () async {
    const failure = NotFoundFailure('budget "b1" has no pending adjustment');
    when(() => repository.cancelBudgetAdjustment('b1',
            periodStart: DateTime(2026)))
        .thenAnswer((_) async => const Left(failure));

    final result = await usecase('b1', periodStart: DateTime(2026));

    expect(result.getLeft().toNullable(), failure);
  });
}
