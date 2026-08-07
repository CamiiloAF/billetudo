import 'package:billetudo/core/error/result.dart';
import 'package:billetudo/features/settings/domain/usecases/set_featured_budget.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'app_settings_repository_mock.dart';

void main() {
  late MockAppSettingsRepository repository;
  late SetFeaturedBudget setFeaturedBudget;

  setUp(() {
    repository = MockAppSettingsRepository();
    setFeaturedBudget = SetFeaturedBudget(repository);
  });

  test('picks a budget by delegating to the repository', () async {
    when(() => repository.setFeaturedBudgetId(budgetId: 'b1'))
        .thenAnswer((_) async => const Right(unit));

    final result = await setFeaturedBudget(budgetId: 'b1');

    expect(result.isRight(), isTrue);
    verify(() => repository.setFeaturedBudgetId(budgetId: 'b1')).called(1);
  });

  test('clears the pick back to "Automatico" with null', () async {
    when(() => repository.setFeaturedBudgetId(budgetId: null))
        .thenAnswer((_) async => const Right(unit));

    final result = await setFeaturedBudget(budgetId: null);

    expect(result.isRight(), isTrue);
    verify(() => repository.setFeaturedBudgetId(budgetId: null)).called(1);
  });

  test('propagates a repository failure', () async {
    when(() => repository.setFeaturedBudgetId(budgetId: 'b1')).thenAnswer(
      (_) async => const Left(DatabaseFailure('boom')),
    );

    final result = await setFeaturedBudget(budgetId: 'b1');

    expect(result.getLeft().toNullable(), isA<DatabaseFailure>());
  });
}
