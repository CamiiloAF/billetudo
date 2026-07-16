import 'package:billetudo/core/error/result.dart';
import 'package:billetudo/features/categories/domain/entities/category.dart';
import 'package:billetudo/features/categories/domain/entities/category_node.dart';
import 'package:billetudo/features/categories/domain/usecases/watch_categories.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'category_repository_mock.dart';

void main() {
  late MockCategoryRepository repository;
  late WatchCategories watchCategories;

  setUp(() {
    repository = MockCategoryRepository();
    watchCategories = WatchCategories(repository);
  });

  test('expone el stream agrupado del kind pedido', () async {
    final node = CategoryNode(root: buildCategory(id: 'root-1'));
    when(() => repository.watchCategories(CategoryKind.expense))
        .thenAnswer((_) => Stream.value(Right([node])));

    final result = await watchCategories(CategoryKind.expense).first;

    expect(result.getRight().toNullable(), [node]);
  });
}
