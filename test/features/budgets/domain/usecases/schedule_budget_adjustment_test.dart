import 'package:billetudo/core/error/result.dart';
import 'package:billetudo/features/budgets/domain/entities/budget_draft.dart';
import 'package:billetudo/features/budgets/domain/usecases/schedule_budget_adjustment.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'budget_repository_mock.dart';

/// "Ajustar monto — solo el próximo período" (crear): `ScheduleBudgetAdjustment`
/// is a thin pass-through to `BudgetRepository.scheduleBudgetAdjustment`.
void main() {
  late MockBudgetRepository repository;
  late ScheduleBudgetAdjustment usecase;

  setUp(() {
    repository = MockBudgetRepository();
    usecase = ScheduleBudgetAdjustment(repository);
  });

  test('forwards the budget id and the new amount in cents', () async {
    when(
      () => repository.scheduleBudgetAdjustment(
        'b1',
        newAmountMinor: 50000,
      ),
    ).thenAnswer((_) async => const Right(unit));

    final result = await usecase('b1', newAmountMinor: 50000);

    expect(result.getRight().toNullable(), unit);
    verify(
      () => repository.scheduleBudgetAdjustment('b1', newAmountMinor: 50000),
    ).called(1);
  });

  test('forwards a validation failure (e.g. one-off budget) unchanged',
      () async {
    const failure = ValidationFailure(
      'a one-off budget has no next period to adjust',
      field: BudgetDraft.fieldEndDate,
    );
    when(
      () => repository.scheduleBudgetAdjustment(
        'b1',
        newAmountMinor: 50000,
      ),
    ).thenAnswer((_) async => const Left(failure));

    final result = await usecase('b1', newAmountMinor: 50000);

    expect(result.getLeft().toNullable(), failure);
  });
}
