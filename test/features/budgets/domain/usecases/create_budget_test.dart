import 'package:billetudo/core/error/result.dart';
import 'package:billetudo/features/budgets/domain/entities/budget.dart';
import 'package:billetudo/features/budgets/domain/entities/budget_draft.dart';
import 'package:billetudo/features/budgets/domain/repositories/budget_repository.dart';
import 'package:billetudo/features/budgets/domain/usecases/create_budget.dart';
import 'package:billetudo/features/settings/domain/usecases/set_featured_budget.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../budget_fixtures.dart';

class MockBudgetRepository extends Mock implements BudgetRepository {}

class MockSetFeaturedBudget extends Mock implements SetFeaturedBudget {}

/// Discoverability fix (`design-system/billetudo/pages/presupuestos.md`,
/// "Destacar presupuesto en Inicio"): the user's very first active budget is
/// auto-featured on Home so the hero has something meaningful to show
/// without the user ever finding the "Usar como destacado" action. Only the
/// first one — from the second budget onward the existing pick is never
/// silently overridden.
void main() {
  late MockBudgetRepository repository;
  late MockSetFeaturedBudget setFeaturedBudget;
  late CreateBudget useCase;

  final draft = BudgetDraft(
    name: 'Mercado',
    amountMinor: 500000,
    currency: 'COP',
    period: BudgetPeriod.monthly,
    startDate: DateTime(2026, 7, 1),
    recurring: true,
  );

  setUpAll(() {
    registerFallbackValue(draft);
  });

  setUp(() {
    repository = MockBudgetRepository();
    setFeaturedBudget = MockSetFeaturedBudget();
    useCase = CreateBudget(repository, setFeaturedBudget);
    when(() => setFeaturedBudget(budgetId: any(named: 'budgetId')))
        .thenAnswer((_) async => const Right(unit));
  });

  test(
      'creating the first active budget (count == 0) calls SetFeaturedBudget '
      'after a successful insert', () async {
    final created = buildBudget(id: 'b1', startDate: DateTime(2026, 7, 1));
    when(() => repository.countActiveBudgets())
        .thenAnswer((_) async => const Right(0));
    when(() => repository.createBudget(any()))
        .thenAnswer((_) async => Right(created));

    final result = await useCase(draft);

    expect(result.getRight().toNullable(), created);
    verify(() => setFeaturedBudget(budgetId: 'b1')).called(1);
  });

  test(
      'creating a second (or later) active budget (count > 0) never calls '
      'SetFeaturedBudget — an existing pick is never silently overridden',
      () async {
    final created = buildBudget(id: 'b2', startDate: DateTime(2026, 7, 1));
    when(() => repository.countActiveBudgets())
        .thenAnswer((_) async => const Right(2));
    when(() => repository.createBudget(any()))
        .thenAnswer((_) async => Right(created));

    final result = await useCase(draft);

    expect(result.getRight().toNullable(), created);
    verifyNever(() => setFeaturedBudget(budgetId: any(named: 'budgetId')));
  });

  test(
      'a failed insert never calls SetFeaturedBudget, even for the first '
      'budget', () async {
    when(() => repository.countActiveBudgets())
        .thenAnswer((_) async => const Right(0));
    when(() => repository.createBudget(any())).thenAnswer(
      (_) async => const Left(DatabaseFailure('insert failed')),
    );

    final result = await useCase(draft);

    expect(result.isLeft(), isTrue);
    verifyNever(() => setFeaturedBudget(budgetId: any(named: 'budgetId')));
  });

  test(
      'a failed count is treated as "not the first" — creation still '
      'succeeds but SetFeaturedBudget is never called', () async {
    final created = buildBudget(id: 'b3', startDate: DateTime(2026, 7, 1));
    when(() => repository.countActiveBudgets()).thenAnswer(
      (_) async => const Left(DatabaseFailure('count failed')),
    );
    when(() => repository.createBudget(any()))
        .thenAnswer((_) async => Right(created));

    final result = await useCase(draft);

    expect(result.getRight().toNullable(), created);
    verifyNever(() => setFeaturedBudget(budgetId: any(named: 'budgetId')));
  });
}
