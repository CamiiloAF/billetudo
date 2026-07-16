import 'package:billetudo/core/error/result.dart';
import 'package:billetudo/features/categories/domain/usecases/restore_category.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'category_repository_mock.dart';

void main() {
  late MockCategoryRepository repository;
  late RestoreCategory restoreCategory;

  setUp(() {
    repository = MockCategoryRepository();
    restoreCategory = RestoreCategory(repository);
  });

  test('delega directo en el repositorio', () async {
    when(() => repository.restoreCategory('cat-1'))
        .thenAnswer((_) async => const Right(unit));

    final result = await restoreCategory('cat-1');

    expect(result.isRight(), isTrue);
    verify(() => repository.restoreCategory('cat-1')).called(1);
  });

  test('propaga el fallo si la categoría no existe', () async {
    when(() => repository.restoreCategory('no-existe')).thenAnswer(
      (_) async => const Left(NotFoundFailure('no existe')),
    );

    final result = await restoreCategory('no-existe');

    expect(result.getLeft().toNullable(), isA<NotFoundFailure>());
  });
}
