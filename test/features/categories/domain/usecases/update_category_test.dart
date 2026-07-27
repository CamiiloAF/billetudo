import 'package:billetudo/core/error/result.dart';
import 'package:billetudo/features/categories/domain/entities/category.dart';
import 'package:billetudo/features/categories/domain/entities/category_deletion_impact.dart';
import 'package:billetudo/features/categories/domain/entities/category_draft.dart';
import 'package:billetudo/features/categories/domain/usecases/update_category.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'category_repository_mock.dart';

void main() {
  late MockCategoryRepository repository;
  late UpdateCategory updateCategory;

  setUpAll(registerCategoryFallbacks);

  setUp(() {
    repository = MockCategoryRepository();
    updateCategory = UpdateCategory(repository);
    when(() => repository.updateCategory(any())).thenAnswer(
      (invocation) async => Right(
        buildCategory(
          id: (invocation.positionalArguments.first as CategoryDraft).id!,
        ),
      ),
    );
  });

  test('falla con ValidationFailure si el draft no trae id', () async {
    const draft = CategoryDraft(name: 'X', kind: CategoryKind.expense);

    final result = await updateCategory(draft);

    final failure = result.getLeft().toNullable()! as ValidationFailure;
    expect(failure.field, CategoryDraft.fieldId);
    verifyNever(() => repository.getCategory(any()));
  });

  group('renombrar / icono / color', () {
    test('nunca toca Transactions.categoryId: solo llama updateCategory',
        () async {
      when(() => repository.getCategory('cat-1'))
          .thenAnswer((_) async => Right(buildCategory()));

      final result = await updateCategory(
        const CategoryDraft(
          id: 'cat-1',
          name: 'Comida renombrada',
          kind: CategoryKind.expense,
          icon: 'utensils',
          color: 'mint',
        ),
      );

      expect(result.isRight(), isTrue);
      verify(() => repository.updateCategory(any())).called(1);
      verifyNever(() => repository.reassignTransactions(any(), any()));
      verifyNever(() => repository.clearTransactionCategory(any()));
    });
  });

  group('subcategoría', () {
    test('mueve a otro parentId root del mismo kind (reclasificación)',
        () async {
      when(() => repository.getCategory('sub-1')).thenAnswer(
        (_) async => Right(
          buildCategory(
            id: 'sub-1',
            parentId: 'root-1',
          ),
        ),
      );
      when(() => repository.getCategory('root-2')).thenAnswer(
        (_) async => Right(
          buildCategory(id: 'root-2'),
        ),
      );

      final result = await updateCategory(
        const CategoryDraft(
          id: 'sub-1',
          name: 'Restaurantes',
          kind: CategoryKind.expense,
          parentId: 'root-2',
        ),
      );

      expect(result.isRight(), isTrue);
      final captured = verify(() => repository.updateCategory(captureAny()))
          .captured
          .single as CategoryDraft;
      expect(captured.parentId, 'root-2');
    });

    test('rechaza cambio de kind en una subcategoría', () async {
      when(() => repository.getCategory('sub-1')).thenAnswer(
        (_) async => Right(
          buildCategory(
            id: 'sub-1',
            parentId: 'root-1',
          ),
        ),
      );

      final result = await updateCategory(
        const CategoryDraft(
          id: 'sub-1',
          name: 'Restaurantes',
          kind: CategoryKind.income,
          parentId: 'root-1',
        ),
      );

      final failure = result.getLeft().toNullable()! as ValidationFailure;
      expect(failure.field, CategoryDraft.fieldKind);
      verifyNever(() => repository.updateCategory(any()));
    });

    test('rechaza mover a un padre de otro kind', () async {
      when(() => repository.getCategory('sub-1')).thenAnswer(
        (_) async => Right(
          buildCategory(
            id: 'sub-1',
            parentId: 'root-1',
          ),
        ),
      );
      when(() => repository.getCategory('root-income')).thenAnswer(
        (_) async => Right(
          buildCategory(id: 'root-income', kind: CategoryKind.income),
        ),
      );

      final result = await updateCategory(
        const CategoryDraft(
          id: 'sub-1',
          name: 'Restaurantes',
          kind: CategoryKind.expense,
          parentId: 'root-income',
        ),
      );

      final failure = result.getLeft().toNullable()! as ValidationFailure;
      expect(failure.field, CategoryDraft.fieldParentId);
    });

    test('rechaza convertirse en raíz', () async {
      when(() => repository.getCategory('sub-1')).thenAnswer(
        (_) async => Right(buildCategory(id: 'sub-1', parentId: 'root-1')),
      );

      final result = await updateCategory(
        const CategoryDraft(id: 'sub-1', name: 'X', kind: CategoryKind.expense),
      );

      final failure = result.getLeft().toNullable()! as ValidationFailure;
      expect(failure.field, CategoryDraft.fieldParentId);
    });
  });

  group('categoría raíz', () {
    test('rechaza convertirse en subcategoría', () async {
      when(() => repository.getCategory('root-1'))
          .thenAnswer((_) async => Right(buildCategory(id: 'root-1')));

      final result = await updateCategory(
        const CategoryDraft(
          id: 'root-1',
          name: 'X',
          kind: CategoryKind.expense,
          parentId: 'root-2',
        ),
      );

      final failure = result.getLeft().toNullable()! as ValidationFailure;
      expect(failure.field, CategoryDraft.fieldParentId);
    });

    test('permite cambiar el kind si no tiene subcategorías activas', () async {
      when(() => repository.getCategory('root-1')).thenAnswer(
        (_) async => Right(buildCategory(id: 'root-1')),
      );
      when(() => repository.getDeletionImpact('root-1')).thenAnswer(
        (_) async => const Right(
          CategoryDeletionImpact(
            hasActiveSubcategories: false,
            transactionCount: 0,
          ),
        ),
      );

      final result = await updateCategory(
        const CategoryDraft(
          id: 'root-1',
          name: 'Ahora es ingreso',
          kind: CategoryKind.income,
        ),
      );

      expect(result.isRight(), isTrue);
    });

    test(
        'rechaza cambiar el kind cuando la raíz tiene subcategorías '
        'activas', () async {
      when(() => repository.getCategory('root-1')).thenAnswer(
        (_) async => Right(buildCategory(id: 'root-1')),
      );
      when(() => repository.getDeletionImpact('root-1')).thenAnswer(
        (_) async => const Right(
          CategoryDeletionImpact(
            hasActiveSubcategories: true,
            transactionCount: 0,
          ),
        ),
      );

      final result = await updateCategory(
        const CategoryDraft(
          id: 'root-1',
          name: 'Transporte',
          kind: CategoryKind.income,
        ),
      );

      final failure = result.getLeft().toNullable()! as ValidationFailure;
      expect(failure.field, CategoryDraft.fieldKind);
      verifyNever(() => repository.updateCategory(any()));
    });
  });
}
