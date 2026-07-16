import 'package:billetudo/core/error/result.dart';
import 'package:billetudo/features/categories/domain/usecases/seed_default_categories.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'category_repository_mock.dart';

void main() {
  late MockCategoryRepository repository;
  late SeedDefaultCategories seedDefaultCategories;

  setUp(() {
    repository = MockCategoryRepository();
    seedDefaultCategories = SeedDefaultCategories(repository);
  });

  test('HU-06: siembra el set semilla cuando el usuario no tiene categorías',
      () async {
    when(() => repository.hasAnyCategory())
        .thenAnswer((_) async => const Right(false));
    when(() => repository.seedDefaultCategories())
        .thenAnswer((_) async => const Right(unit));

    final result = await seedDefaultCategories();

    expect(result.isRight(), isTrue);
    verify(() => repository.seedDefaultCategories()).called(1);
  });

  test('es idempotente: no siembra si el usuario ya tiene categorías',
      () async {
    when(() => repository.hasAnyCategory())
        .thenAnswer((_) async => const Right(true));

    final result = await seedDefaultCategories();

    expect(result.isRight(), isTrue);
    verifyNever(() => repository.seedDefaultCategories());
  });

  test('propaga el fallo si no puede verificar si ya hay categorías', () async {
    when(() => repository.hasAnyCategory())
        .thenAnswer((_) async => const Left(DatabaseFailure('sin disco')));

    final result = await seedDefaultCategories();

    expect(result.getLeft().toNullable(), isA<DatabaseFailure>());
    verifyNever(() => repository.seedDefaultCategories());
  });
}
