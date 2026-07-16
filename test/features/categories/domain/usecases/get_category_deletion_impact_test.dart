import 'package:billetudo/core/error/result.dart';
import 'package:billetudo/features/categories/domain/entities/category_deletion_impact.dart';
import 'package:billetudo/features/categories/domain/usecases/get_category_deletion_impact.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'category_repository_mock.dart';

void main() {
  late MockCategoryRepository repository;
  late GetCategoryDeletionImpact getImpact;

  setUp(() {
    repository = MockCategoryRepository();
    getImpact = GetCategoryDeletionImpact(repository);
  });

  test('delega directo en el repositorio', () async {
    when(() => repository.getDeletionImpact('cat-1')).thenAnswer(
      (_) async => const Right(
        CategoryDeletionImpact(
          hasActiveSubcategories: true,
          transactionCount: 3,
        ),
      ),
    );

    final result = await getImpact('cat-1');

    final impact = result.getRight().toNullable()!;
    expect(impact.hasActiveSubcategories, isTrue);
    expect(impact.transactionCount, 3);
  });
}
