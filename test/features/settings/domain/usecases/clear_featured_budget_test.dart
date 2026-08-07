import 'package:billetudo/core/error/result.dart';
import 'package:billetudo/features/settings/domain/usecases/clear_featured_budget.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'app_settings_repository_mock.dart';

void main() {
  late MockAppSettingsRepository repository;
  late ClearFeaturedBudget clearFeaturedBudget;

  setUp(() {
    repository = MockAppSettingsRepository();
    clearFeaturedBudget = ClearFeaturedBudget(repository);
  });

  test('clears the featured budget by delegating to the repository',
      () async {
    when(() => repository.clearFeaturedBudget())
        .thenAnswer((_) async => const Right<Failure, Unit>(unit));

    final result = await clearFeaturedBudget();

    expect(result.isRight(), isTrue);
    verify(() => repository.clearFeaturedBudget()).called(1);
  });

  test('propagates a repository failure', () async {
    when(() => repository.clearFeaturedBudget()).thenAnswer(
      (_) async => const Left(DatabaseFailure('boom')),
    );

    final result = await clearFeaturedBudget();

    expect(result.getLeft().toNullable(), isA<DatabaseFailure>());
  });
}
