import 'package:billetudo/core/error/result.dart';
import 'package:billetudo/features/categories/domain/usecases/get_category_subtree_ids.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'category_repository_mock.dart';

void main() {
  late MockCategoryRepository repository;
  late GetCategorySubtreeIds getCategorySubtreeIds;

  setUp(() {
    repository = MockCategoryRepository();
    getCategorySubtreeIds = GetCategorySubtreeIds(repository);
  });

  test('expande una categoría raíz a sí misma + sus subcategorías activas',
      () async {
    final root = buildCategory(id: 'root-1');
    when(() => repository.getCategory('root-1'))
        .thenAnswer((_) async => Right(root));
    when(() => repository.getActiveSubcategories('root-1')).thenAnswer(
      (_) async => Right([
        buildCategory(id: 'sub-1', parentId: 'root-1'),
        buildCategory(id: 'sub-2', parentId: 'root-1'),
      ]),
    );

    final result = await getCategorySubtreeIds('root-1');

    expect(
      result.getRight().toNullable(),
      {'root-1', 'sub-1', 'sub-2'},
    );
  });

  test('una raíz sin subcategorías se expande solo a sí misma', () async {
    final root = buildCategory(id: 'root-1');
    when(() => repository.getCategory('root-1'))
        .thenAnswer((_) async => Right(root));
    when(() => repository.getActiveSubcategories('root-1'))
        .thenAnswer((_) async => const Right([]));

    final result = await getCategorySubtreeIds('root-1');

    expect(result.getRight().toNullable(), {'root-1'});
  });

  test('una subcategoría no se expande (ya es su propio id)', () async {
    final sub = buildCategory(id: 'sub-1', parentId: 'root-1');
    when(() => repository.getCategory('sub-1'))
        .thenAnswer((_) async => Right(sub));

    final result = await getCategorySubtreeIds('sub-1');

    expect(result.getRight().toNullable(), {'sub-1'});
    verifyNever(() => repository.getActiveSubcategories(any()));
  });

  test('propaga el failure cuando la categoría no existe', () async {
    when(() => repository.getCategory('missing')).thenAnswer(
      (_) async => const Left(NotFoundFailure('no existe')),
    );

    final result = await getCategorySubtreeIds('missing');

    expect(result.isLeft(), isTrue);
  });

  test('propaga el failure cuando falla la lectura de subcategorías',
      () async {
    final root = buildCategory(id: 'root-1');
    when(() => repository.getCategory('root-1'))
        .thenAnswer((_) async => Right(root));
    when(() => repository.getActiveSubcategories('root-1')).thenAnswer(
      (_) async => const Left(DatabaseFailure('boom')),
    );

    final result = await getCategorySubtreeIds('root-1');

    expect(result.isLeft(), isTrue);
  });
}
