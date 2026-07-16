import 'package:billetudo/core/error/result.dart';
import 'package:billetudo/features/categories/domain/entities/category.dart';
import 'package:billetudo/features/categories/domain/usecases/watch_parent_candidates.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'category_repository_mock.dart';

void main() {
  late MockCategoryRepository repository;
  late WatchParentCandidates watchParentCandidates;

  setUp(() {
    repository = MockCategoryRepository();
    watchParentCandidates = WatchParentCandidates(repository);
  });

  test('pasa el kind y el excludingId al repositorio', () async {
    final candidate = buildCategory(id: 'root-2');
    when(
      () => repository.watchParentCandidates(
        CategoryKind.expense,
        excludingId: 'root-1',
      ),
    ).thenAnswer((_) => Stream.value(Right([candidate])));

    final result = await watchParentCandidates(
      CategoryKind.expense,
      excludingId: 'root-1',
    ).first;

    expect(result.getRight().toNullable(), [candidate]);
  });
}
