import 'package:billetudo/core/error/result.dart';
import 'package:billetudo/features/budgets/domain/usecases/update_budget_adjustment.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'budget_repository_mock.dart';

/// "Ajustar monto — solo el próximo período" (editar): `UpdateBudgetAdjustment`
/// is a thin pass-through to `BudgetRepository.updateBudgetAdjustment`.
void main() {
  late MockBudgetRepository repository;
  late UpdateBudgetAdjustment usecase;

  setUp(() {
    repository = MockBudgetRepository();
    usecase = UpdateBudgetAdjustment(repository);
  });

  test('forwards the budget id and the edited amount in cents', () async {
    when(
      () => repository.updateBudgetAdjustment(
        'b1',
        newAmountMinor: 75000,
      ),
    ).thenAnswer((_) async => const Right(unit));

    final result = await usecase('b1', newAmountMinor: 75000);

    expect(result.getRight().toNullable(), unit);
    verify(
      () => repository.updateBudgetAdjustment('b1', newAmountMinor: 75000),
    ).called(1);
  });

  test('forwards a NotFoundFailure when there is no pending fork to edit',
      () async {
    const failure = NotFoundFailure('budget "b1" has no pending adjustment');
    when(
      () => repository.updateBudgetAdjustment(
        'b1',
        newAmountMinor: 75000,
      ),
    ).thenAnswer((_) async => const Left(failure));

    final result = await usecase('b1', newAmountMinor: 75000);

    expect(result.getLeft().toNullable(), failure);
  });
}
