import 'package:billetudo/core/error/result.dart';
import 'package:billetudo/features/budgets/domain/usecases/get_budget_period_window_at.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../budget_fixtures.dart';
import 'budget_repository_mock.dart';

/// `GetBudgetPeriodWindowAt` (Period Nav Bar stepping, `design-system/
/// billetudo/pages/transacciones.md` § "Period Nav Bar en la pantalla
/// principal"): thin delegation to `BudgetPeriodCalculator.windowAt` once the
/// budget itself is fetched — the calculator's own math is covered
/// exhaustively elsewhere, this only checks the wiring.
void main() {
  late MockBudgetRepository repository;
  late GetBudgetPeriodWindowAt usecase;

  setUp(() {
    repository = MockBudgetRepository();
    usecase = GetBudgetPeriodWindowAt(repository);
  });

  test('resolves the window at index from the fetched budget', () async {
    final budget = buildBudget(id: 'b1', startDate: DateTime(2026, 1, 1));
    when(() => repository.getBudget('b1'))
        .thenAnswer((_) async => Right(budget));

    final result = await usecase('b1', 2);

    final window = result.getRight().toNullable();
    expect(window, isNotNull);
    expect(window!.index, 2);
    expect(window.start, DateTime(2026, 3, 1));
    expect(window.endExclusive, DateTime(2026, 4, 1));
  });

  test('forwards a repository failure unchanged', () async {
    const failure = NotFoundFailure('budget "b1" does not exist');
    when(() => repository.getBudget('b1'))
        .thenAnswer((_) async => const Left(failure));

    final result = await usecase('b1', 0);

    expect(result.getLeft().toNullable(), failure);
  });
}
