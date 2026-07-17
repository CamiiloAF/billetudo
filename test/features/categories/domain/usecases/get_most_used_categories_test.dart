import 'package:billetudo/core/error/result.dart';
import 'package:billetudo/features/categories/domain/entities/category.dart';
import 'package:billetudo/features/categories/domain/usecases/get_most_used_categories.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'category_repository_mock.dart';

void main() {
  late MockCategoryRepository repository;
  late GetMostUsedCategories getMostUsedCategories;

  setUp(() {
    repository = MockCategoryRepository();
    getMostUsedCategories = GetMostUsedCategories(repository);
  });

  test('delega en el repositorio (limit por defecto)', () async {
    final categories = [
      buildCategory(),
      buildCategory(id: 'cat-2'),
      buildCategory(id: 'cat-3'),
    ];
    when(
      () => repository.getMostUsedCategories(CategoryKind.expense),
    ).thenAnswer((_) async => Right(categories));

    final result = await getMostUsedCategories(CategoryKind.expense);

    expect(result.getRight().toNullable(), categories);
    verify(
      () => repository.getMostUsedCategories(CategoryKind.expense),
    ).called(1);
  });

  test('respeta un limit explícito', () async {
    when(
      () => repository.getMostUsedCategories(CategoryKind.income, limit: 5),
    ).thenAnswer((_) async => const Right(<Category>[]));

    await getMostUsedCategories(CategoryKind.income, limit: 5);

    verify(
      () => repository.getMostUsedCategories(CategoryKind.income, limit: 5),
    ).called(1);
  });

  test('propaga el failure del repositorio', () async {
    when(
      () => repository.getMostUsedCategories(CategoryKind.expense),
    ).thenAnswer((_) async => const Left(DatabaseFailure('boom')));

    final result = await getMostUsedCategories(CategoryKind.expense);

    expect(result.isLeft(), isTrue);
  });
}
