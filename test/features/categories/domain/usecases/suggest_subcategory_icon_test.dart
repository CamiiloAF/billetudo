import 'package:billetudo/core/error/result.dart';
import 'package:billetudo/features/categories/domain/entities/category.dart';
import 'package:billetudo/features/categories/domain/entities/category_icon_catalog.dart';
import 'package:billetudo/features/categories/domain/usecases/suggest_subcategory_icon.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'category_repository_mock.dart';

void main() {
  late MockCategoryRepository repository;
  late SuggestSubcategoryIcon suggestSubcategoryIcon;

  setUp(() {
    repository = MockCategoryRepository();
    suggestSubcategoryIcon = SuggestSubcategoryIcon(repository);
  });

  test('sin hermanas: sugiere el primer ícono del catálogo', () async {
    when(() => repository.getActiveSubcategories('root-1'))
        .thenAnswer((_) async => const Right(<Category>[]));

    final result = await suggestSubcategoryIcon('root-1');

    expect(result.getRight().toNullable(), CategoryIconCatalog.names.first);
  });

  test('con hermanas: sugiere el primer ícono del catálogo no usado por ellas',
      () async {
    when(() => repository.getActiveSubcategories('root-1')).thenAnswer(
      (_) async => Right([
        buildCategory(
          id: 'sub-1',
          parentId: 'root-1',
          icon: CategoryIconCatalog.names[0],
        ),
        buildCategory(
          id: 'sub-2',
          parentId: 'root-1',
          icon: CategoryIconCatalog.names[1],
        ),
      ]),
    );

    final result = await suggestSubcategoryIcon('root-1');

    expect(result.getRight().toNullable(), CategoryIconCatalog.names[2]);
  });

  test('todo el catálogo en uso: cae de vuelta al primero, sin crashear',
      () async {
    when(() => repository.getActiveSubcategories('root-1')).thenAnswer(
      (_) async => Right([
        for (final name in CategoryIconCatalog.names)
          buildCategory(id: 'sub-$name', parentId: 'root-1', icon: name),
      ]),
    );

    final result = await suggestSubcategoryIcon('root-1');

    expect(result.getRight().toNullable(), CategoryIconCatalog.names.first);
  });

  test('propaga el failure del repositorio', () async {
    when(() => repository.getActiveSubcategories('root-1'))
        .thenAnswer((_) async => const Left(DatabaseFailure('boom')));

    final result = await suggestSubcategoryIcon('root-1');

    expect(result.isLeft(), isTrue);
  });
}
