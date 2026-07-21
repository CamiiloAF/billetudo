import 'package:billetudo/core/error/result.dart';
import 'package:billetudo/features/budgets/domain/entities/pending_budget_adjustment.dart';
import 'package:billetudo/features/budgets/domain/usecases/get_pending_budget_adjustment.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'budget_repository_mock.dart';

/// "Ajustar monto — solo el próximo período": `GetPendingBudgetAdjustment` is a
/// thin pass-through to `BudgetRepository.getPendingAdjustment` — the entry
/// point's sheet uses its `null`-ness alone to pick "crear" vs "editar/cancelar".
void main() {
  late MockBudgetRepository repository;
  late GetPendingBudgetAdjustment usecase;

  setUp(() {
    repository = MockBudgetRepository();
    usecase = GetPendingBudgetAdjustment(repository);
  });

  test('returns Right(null) when the budget has no pending fork', () async {
    when(() => repository.getPendingAdjustment('b1', periodStart: DateTime(2026)))
        .thenAnswer((_) async => const Right(null));

    final result = await usecase('b1', periodStart: DateTime(2026));

    expect(result.getRight().toNullable(), isNull);
    verify(() => repository.getPendingAdjustment('b1', periodStart: DateTime(2026))).called(1);
  });

  test('returns Right(adjustment) when the budget has a pending fork',
      () async {
    final adjustment = PendingBudgetAdjustment(
      newAmountMinor: 50000,
      effectiveFrom: DateTime(2026, 8, 1),
      resumeAmountMinor: 100000,
      resumeFrom: DateTime(2026, 9, 1),
    );
    when(() => repository.getPendingAdjustment('b1', periodStart: DateTime(2026)))
        .thenAnswer((_) async => Right(adjustment));

    final result = await usecase('b1', periodStart: DateTime(2026));

    final value = result.getRight().toNullable();
    expect(value, isNotNull);
    expect(value!.newAmountMinor, 50000);
    expect(value.resumeAmountMinor, 100000);
  });

  test('forwards a repository failure unchanged', () async {
    const failure = NotFoundFailure('budget "b1" does not exist');
    when(() => repository.getPendingAdjustment('b1', periodStart: DateTime(2026)))
        .thenAnswer((_) async => const Left(failure));

    final result = await usecase('b1', periodStart: DateTime(2026));

    expect(result.getLeft().toNullable(), failure);
  });
}
