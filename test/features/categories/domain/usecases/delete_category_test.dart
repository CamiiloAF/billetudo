import 'package:billetudo/core/error/result.dart';
import 'package:billetudo/features/categories/domain/entities/category.dart';
import 'package:billetudo/features/categories/domain/entities/category_deletion_impact.dart';
import 'package:billetudo/features/categories/domain/usecases/delete_category.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'category_repository_mock.dart';

void main() {
  late MockCategoryRepository repository;
  late DeleteCategory deleteCategory;

  setUp(() {
    repository = MockCategoryRepository();
    deleteCategory = DeleteCategory(repository);
    when(() => repository.softDeleteCategory(any()))
        .thenAnswer((_) async => const Right(unit));
    when(() => repository.cascadeDeleteCategory(any()))
        .thenAnswer((_) async => const Right(unit));
    when(() => repository.reassignSubcategories(any(), any()))
        .thenAnswer((_) async => const Right(unit));
    when(() => repository.reassignTransactions(any(), any()))
        .thenAnswer((_) async => const Right(unit));
    when(() => repository.clearTransactionCategory(any()))
        .thenAnswer((_) async => const Right(unit));
  });

  void givenImpact({
    bool hasActiveSubcategories = false,
    int transactionCount = 0,
  }) {
    when(() => repository.getDeletionImpact(any())).thenAnswer(
      (_) async => Right(
        CategoryDeletionImpact(
          hasActiveSubcategories: hasActiveSubcategories,
          transactionCount: transactionCount,
        ),
      ),
    );
  }

  void givenCategory(Category category) {
    when(() => repository.getCategory(category.id))
        .thenAnswer((_) async => Right(category));
  }

  group('caso 1: sin dependientes', () {
    test('hace soft delete vía deletedAt, nunca tombstonedAt', () async {
      givenImpact();
      givenCategory(buildCategory());

      final result = await deleteCategory('cat-1');

      expect(result.isRight(), isTrue);
      verify(() => repository.softDeleteCategory('cat-1')).called(1);
    });

    test('consulta el impacto antes de borrar, nunca al revés', () async {
      givenImpact();
      givenCategory(buildCategory());

      await deleteCategory('cat-1');

      verifyInOrder([
        () => repository.getDeletionImpact('cat-1'),
        () => repository.softDeleteCategory('cat-1'),
      ]);
    });

    test('si no puede calcular el impacto, no borra', () async {
      when(() => repository.getDeletionImpact(any()))
          .thenAnswer((_) async => const Left(DatabaseFailure('sin disco')));

      final result = await deleteCategory('cat-1');

      expect(result.getLeft().toNullable(), isA<DatabaseFailure>());
      verifyNever(() => repository.softDeleteCategory(any()));
    });
  });

  group('caso 2: con transacciones asociadas', () {
    test('exige una resolución explícita antes de borrar', () async {
      givenImpact(transactionCount: 5);
      givenCategory(buildCategory());

      final result = await deleteCategory('cat-1');

      final failure = result.getLeft().toNullable()! as ValidationFailure;
      expect(failure.field, DeleteCategory.transactionResolutionField);
      verifyNever(() => repository.softDeleteCategory(any()));
    });

    test(
        'reasigna las transacciones a otra categoría del mismo kind luego '
        'borra', () async {
      givenImpact(transactionCount: 5);
      givenCategory(buildCategory());
      when(() => repository.getCategory('cat-2')).thenAnswer(
        (_) async => Right(buildCategory(id: 'cat-2')),
      );

      final result = await deleteCategory(
        'cat-1',
        transactionResolution: const TransactionResolution.reassign('cat-2'),
      );

      expect(result.isRight(), isTrue);
      verifyInOrder([
        () => repository.reassignTransactions('cat-1', 'cat-2'),
        () => repository.softDeleteCategory('cat-1'),
      ]);
    });

    test('rechaza reasignar a una categoría de otro kind', () async {
      givenImpact(transactionCount: 5);
      givenCategory(buildCategory());
      when(() => repository.getCategory('cat-2')).thenAnswer(
        (_) async =>
            Right(buildCategory(id: 'cat-2', kind: CategoryKind.income)),
      );

      final result = await deleteCategory(
        'cat-1',
        transactionResolution: const TransactionResolution.reassign('cat-2'),
      );

      expect(result.isLeft(), isTrue);
      verifyNever(() => repository.reassignTransactions(any(), any()));
      verifyNever(() => repository.softDeleteCategory(any()));
    });

    test('deja las transacciones sin categoría luego borra', () async {
      givenImpact(transactionCount: 5);
      givenCategory(buildCategory());

      final result = await deleteCategory(
        'cat-1',
        transactionResolution: const TransactionResolution.clear(),
      );

      expect(result.isRight(), isTrue);
      verifyInOrder([
        () => repository.clearTransactionCategory('cat-1'),
        () => repository.softDeleteCategory('cat-1'),
      ]);
    });
  });

  group('caso 3: raíz con subcategorías activas', () {
    test('rechaza el borrado directo sin resolución', () async {
      givenImpact(hasActiveSubcategories: true);
      givenCategory(buildCategory(id: 'root-1'));

      final result = await deleteCategory('root-1');

      final failure = result.getLeft().toNullable()! as ValidationFailure;
      expect(failure.field, DeleteCategory.subcategoryResolutionField);
      verifyNever(() => repository.softDeleteCategory(any()));
      verifyNever(() => repository.cascadeDeleteCategory(any()));
    });

    test(
        'reasigna cada subcategoría a otro root del mismo kind luego '
        'borra la raíz', () async {
      givenImpact(hasActiveSubcategories: true);
      givenCategory(buildCategory(id: 'root-1'));
      when(() => repository.getCategory('root-2')).thenAnswer(
        (_) async => Right(buildCategory(id: 'root-2')),
      );

      final result = await deleteCategory(
        'root-1',
        subcategoryResolution: const SubcategoryResolution.reassign('root-2'),
      );

      expect(result.isRight(), isTrue);
      verifyInOrder([
        () => repository.reassignSubcategories('root-1', 'root-2'),
        () => repository.softDeleteCategory('root-1'),
      ]);
      verifyNever(() => repository.cascadeDeleteCategory(any()));
    });

    test('rechaza reasignar a un root de otro kind', () async {
      givenImpact(hasActiveSubcategories: true);
      givenCategory(buildCategory(id: 'root-1'));
      when(() => repository.getCategory('root-2')).thenAnswer(
        (_) async =>
            Right(buildCategory(id: 'root-2', kind: CategoryKind.income)),
      );

      final result = await deleteCategory(
        'root-1',
        subcategoryResolution: const SubcategoryResolution.reassign('root-2'),
      );

      expect(result.isLeft(), isTrue);
      verifyNever(() => repository.reassignSubcategories(any(), any()));
    });

    test(
        'elimina en cascada la raíz y sus subcategorías, sin llamar a '
        'softDeleteCategory por separado', () async {
      givenImpact(hasActiveSubcategories: true);
      givenCategory(buildCategory(id: 'root-1'));

      final result = await deleteCategory(
        'root-1',
        subcategoryResolution: const SubcategoryResolution.cascade(),
      );

      expect(result.isRight(), isTrue);
      verify(() => repository.cascadeDeleteCategory('root-1')).called(1);
      verifyNever(() => repository.softDeleteCategory(any()));
    });
  });

  group('casos combinados: transacciones + subcategorías', () {
    test('resuelve ambas reglas antes de completar el borrado', () async {
      givenImpact(hasActiveSubcategories: true, transactionCount: 2);
      givenCategory(buildCategory(id: 'root-1'));
      when(() => repository.getCategory('cat-2')).thenAnswer(
        (_) async => Right(buildCategory(id: 'cat-2')),
      );
      when(() => repository.getCategory('root-2')).thenAnswer(
        (_) async => Right(buildCategory(id: 'root-2')),
      );

      final result = await deleteCategory(
        'root-1',
        transactionResolution: const TransactionResolution.reassign('cat-2'),
        subcategoryResolution: const SubcategoryResolution.reassign('root-2'),
      );

      expect(result.isRight(), isTrue);
      verifyInOrder([
        () => repository.reassignTransactions('root-1', 'cat-2'),
        () => repository.reassignSubcategories('root-1', 'root-2'),
        () => repository.softDeleteCategory('root-1'),
      ]);
    });

    test('no toca subcategorías si falla resolver las transacciones', () async {
      givenImpact(hasActiveSubcategories: true, transactionCount: 2);
      givenCategory(buildCategory(id: 'root-1'));

      final result = await deleteCategory('root-1');

      expect(result.isLeft(), isTrue);
      verifyNever(() => repository.reassignSubcategories(any(), any()));
      verifyNever(() => repository.cascadeDeleteCategory(any()));
    });
  });
}
