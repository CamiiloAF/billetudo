import 'package:billetudo/core/error/result.dart';
import 'package:billetudo/features/categories/domain/entities/category.dart';
import 'package:billetudo/features/categories/domain/entities/category_draft.dart';
import 'package:billetudo/features/categories/domain/usecases/create_category.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'category_repository_mock.dart';

void main() {
  late MockCategoryRepository repository;
  late CreateCategory createCategory;

  setUpAll(registerCategoryFallbacks);

  setUp(() {
    repository = MockCategoryRepository();
    createCategory = CreateCategory(repository);
    when(() => repository.createCategory(any())).thenAnswer(
      (invocation) async => Right(
        buildCategory(
          name: (invocation.positionalArguments.first as CategoryDraft).name,
        ),
      ),
    );
  });

  group('HU-01: categoría raíz', () {
    test('crea la raíz sin consultar el repositorio por un padre', () async {
      const draft = CategoryDraft(
        name: 'Comida y bebida',
        kind: CategoryKind.expense,
      );

      final result = await createCategory(draft);

      expect(result.isRight(), isTrue);
      verifyNever(() => repository.getCategory(any()));
      verify(() => repository.createCategory(any())).called(1);
    });

    test('falla con ValidationFailure si el nombre está vacío', () async {
      const draft = CategoryDraft(name: '  ', kind: CategoryKind.expense);

      final result = await createCategory(draft);

      final failure = result.getLeft().toNullable()! as ValidationFailure;
      expect(failure.field, CategoryDraft.fieldName);
      verifyNever(() => repository.createCategory(any()));
    });

    test('falla con ValidationFailure si el nombre excede 100 caracteres',
        () async {
      final draft = CategoryDraft(
        name: 'a' * 101,
        kind: CategoryKind.expense,
      );

      final result = await createCategory(draft);

      final failure = result.getLeft().toNullable()! as ValidationFailure;
      expect(failure.field, CategoryDraft.fieldName);
    });
  });

  group('HU-02: subcategoría', () {
    test('hereda el kind del padre e ignora el kind pasado por la UI',
        () async {
      when(() => repository.getCategory('root-1')).thenAnswer(
        (_) async => Right(
          buildCategory(id: 'root-1', kind: CategoryKind.income),
        ),
      );

      const draft = CategoryDraft(
        name: 'Bono',
        // El formulario manda 'expense' pero el padre es 'income'.
        kind: CategoryKind.expense,
        parentId: 'root-1',
      );

      await createCategory(draft);

      final captured = verify(() => repository.createCategory(captureAny()))
          .captured
          .single as CategoryDraft;
      expect(captured.kind, CategoryKind.income);
      expect(captured.parentId, 'root-1');
    });

    test('falla con ValidationFailure si el parentId no existe', () async {
      when(() => repository.getCategory('no-existe')).thenAnswer(
        (_) async => const Left(NotFoundFailure('no existe')),
      );

      final result = await createCategory(
        const CategoryDraft(
          name: 'Sub',
          kind: CategoryKind.expense,
          parentId: 'no-existe',
        ),
      );

      final failure = result.getLeft().toNullable()! as ValidationFailure;
      expect(failure.field, CategoryDraft.fieldParentId);
      verifyNever(() => repository.createCategory(any()));
    });

    test(
        'falla con ValidationFailure si el padre ya es a su vez una '
        'subcategoría (máximo 2 niveles)', () async {
      when(() => repository.getCategory('sub-1')).thenAnswer(
        (_) async => Right(
          buildCategory(id: 'sub-1', parentId: 'root-1'),
        ),
      );

      final result = await createCategory(
        const CategoryDraft(
          name: 'Nieta',
          kind: CategoryKind.expense,
          parentId: 'sub-1',
        ),
      );

      final failure = result.getLeft().toNullable()! as ValidationFailure;
      expect(failure.field, CategoryDraft.fieldParentId);
      verifyNever(() => repository.createCategory(any()));
    });

    test('propaga un fallo de infraestructura al consultar el padre', () async {
      when(() => repository.getCategory('root-1')).thenAnswer(
        (_) async => const Left(DatabaseFailure('sin disco')),
      );

      final result = await createCategory(
        const CategoryDraft(
          name: 'Sub',
          kind: CategoryKind.expense,
          parentId: 'root-1',
        ),
      );

      expect(result.getLeft().toNullable(), isA<DatabaseFailure>());
    });
  });
}
