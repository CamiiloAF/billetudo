import 'package:billetudo/core/error/result.dart';
import 'package:billetudo/features/categories/domain/usecases/reorder_categories.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'category_repository_mock.dart';

void main() {
  late MockCategoryRepository repository;
  late ReorderCategories reorderCategories;

  setUp(() {
    repository = MockCategoryRepository();
    reorderCategories = ReorderCategories(repository);
    when(() => repository.reorderCategories(any()))
        .thenAnswer((_) async => const Right(unit));
  });

  test('persiste el nuevo orden delegando al repositorio', () async {
    final result = await reorderCategories(['b', 'c', 'a']);

    expect(result.isRight(), isTrue);
    verify(() => repository.reorderCategories(['b', 'c', 'a'])).called(1);
  });

  test('rechaza un orden con ids repetidos', () async {
    final result = await reorderCategories(['a', 'a']);

    final failure = result.getLeft().toNullable()! as ValidationFailure;
    expect(failure.field, ReorderCategories.orderedIdsField);
    verifyNever(() => repository.reorderCategories(any()));
  });
}
