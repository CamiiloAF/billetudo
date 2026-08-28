import 'package:billetudo/core/error/result.dart';
import 'package:billetudo/features/budgets/domain/entities/budget_with_progress.dart';
import 'package:billetudo/features/home/domain/usecases/watch_has_any_budget.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../../budgets/domain/usecases/budget_repository_mock.dart';
import '../home_hero_fixtures.dart';

/// Tells `HomeHeroStateResolver` apart "never created one" from "has some,
/// none featured" whenever `WatchFeaturedBudgetProgress` emits `null`.
void main() {
  late MockBudgetRepository repository;
  late WatchHasAnyBudget useCase;

  setUp(() {
    repository = MockBudgetRepository();
    useCase = WatchHasAnyBudget(repository);
  });

  test('emite false sin presupuestos activos', () async {
    when(() => repository.watchActiveBudgets()).thenAnswer(
      (_) => Stream.value(const Right(<BudgetWithProgress>[])),
    );

    final result = await useCase().first;

    expect(result.getRight().toNullable(), isFalse);
  });

  test('emite true con al menos un presupuesto activo', () async {
    when(() => repository.watchActiveBudgets()).thenAnswer(
      (_) => Stream.value(
        Right([
          buildBudgetWithProgress(id: 'b1', createdAt: DateTime(2026, 1, 1)),
        ]),
      ),
    );

    final result = await useCase().first;

    expect(result.getRight().toNullable(), isTrue);
  });

  test('propaga un fallo del repositorio como Left', () async {
    const failure = DatabaseFailure('boom');
    when(() => repository.watchActiveBudgets()).thenAnswer(
      (_) => Stream.value(const Left(failure)),
    );

    final result = await useCase().first;

    expect(result.getLeft().toNullable(), failure);
  });
}
