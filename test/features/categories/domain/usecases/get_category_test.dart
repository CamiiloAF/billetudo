import 'package:billetudo/core/error/result.dart';
import 'package:billetudo/features/categories/domain/usecases/get_category.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'category_repository_mock.dart';

void main() {
  late MockCategoryRepository repository;
  late GetCategory getCategory;

  setUp(() {
    repository = MockCategoryRepository();
    getCategory = GetCategory(repository);
  });

  test('delega directo en el repositorio', () async {
    final category = buildCategory();
    when(() => repository.getCategory('cat-1'))
        .thenAnswer((_) async => Right(category));

    final result = await getCategory('cat-1');

    expect(result.getRight().toNullable(), category);
  });

  test('propaga el failure cuando no existe', () async {
    when(() => repository.getCategory('missing')).thenAnswer(
      (_) async => const Left(NotFoundFailure('no existe')),
    );

    final result = await getCategory('missing');

    expect(result.isLeft(), isTrue);
  });
}
