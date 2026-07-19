import 'package:billetudo/core/error/result.dart';
import 'package:billetudo/features/categories/domain/entities/category.dart';
import 'package:billetudo/features/categories/domain/entities/category_deletion_impact.dart';
import 'package:billetudo/features/categories/domain/entities/category_draft.dart';
import 'package:billetudo/features/categories/domain/usecases/delete_category.dart';
import 'package:billetudo/features/categories/presentation/cubit/category_form_cubit.dart';
import 'package:billetudo/features/categories/presentation/cubit/category_form_state.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../domain/usecases/category_repository_mock.dart';
import '../usecase_mocks.dart';

void main() {
  late MockCreateCategory createCategory;
  late MockUpdateCategory updateCategory;
  late MockGetCategory getCategory;
  late MockGetCategoryDeletionImpact getDeletionImpact;
  late MockDeleteCategory deleteCategory;

  setUpAll(registerCategoryPresentationFallbacks);

  setUp(() {
    createCategory = MockCreateCategory();
    updateCategory = MockUpdateCategory();
    getCategory = MockGetCategory();
    getDeletionImpact = MockGetCategoryDeletionImpact();
    deleteCategory = MockDeleteCategory();
  });

  CategoryFormCubit build() => CategoryFormCubit(
        createCategory,
        updateCategory,
        getCategory,
        getDeletionImpact,
        deleteCategory,
      );

  group('caso 1: crear categoría raíz', () {
    blocTest<CategoryFormCubit, CategoryFormState>(
      'arranca lista, sin bloqueo de Tipo, con el kind pedido',
      build: build,
      act: (cubit) => cubit.load(kind: CategoryKind.income),
      expect: () => [
        const CategoryFormState(
          status: CategoryFormStatus.ready,
          kind: CategoryKind.income,
        ),
      ],
    );

    blocTest<CategoryFormCubit, CategoryFormState>(
      'submit llama a CreateCategory con el draft armado',
      setUp: () => when(() => createCategory(any())).thenAnswer(
        (_) async => Right(buildCategory(id: 'new-1')),
      ),
      build: build,
      act: (cubit) async {
        await cubit.load();
        cubit.nameChanged('Mercado');
        await cubit.submit();
      },
      verify: (cubit) {
        expect(cubit.state.status, CategoryFormStatus.saved);
        verify(
          () => createCategory(
            const CategoryDraft(name: 'Mercado', kind: CategoryKind.expense),
          ),
        ).called(1);
      },
    );
  });

  group('caso 2: crear subcategoría', () {
    blocTest<CategoryFormCubit, CategoryFormState>(
      'hereda el kind del padre y bloquea Tipo',
      setUp: () => when(() => getCategory('root-1')).thenAnswer(
        (_) async => Right(
          buildCategory(
              id: 'root-1', name: 'Transporte', kind: CategoryKind.income),
        ),
      ),
      build: build,
      act: (cubit) => cubit.load(parentId: 'root-1'),
      expect: () => [
        const CategoryFormState(),
        const CategoryFormState(
          status: CategoryFormStatus.ready,
          parentId: 'root-1',
          parentName: 'Transporte',
          kind: CategoryKind.income,
          kindLockReason: CategoryKindLockReason.subcategory,
        ),
      ],
    );

    blocTest<CategoryFormCubit, CategoryFormState>(
      'hereda también el ícono y el color del padre, no solo el kind',
      setUp: () => when(() => getCategory('root-1')).thenAnswer(
        (_) async => Right(
          buildCategory(
            id: 'root-1',
            name: 'Transporte',
            kind: CategoryKind.income,
            icon: 'bus',
            color: '#FF5733',
          ),
        ),
      ),
      build: build,
      act: (cubit) => cubit.load(parentId: 'root-1'),
      expect: () => [
        const CategoryFormState(),
        const CategoryFormState(
          status: CategoryFormStatus.ready,
          parentId: 'root-1',
          parentName: 'Transporte',
          kind: CategoryKind.income,
          icon: 'bus',
          color: '#FF5733',
          kindLockReason: CategoryKindLockReason.subcategory,
        ),
      ],
    );
  });

  group('caso 3: editar categoría raíz', () {
    blocTest<CategoryFormCubit, CategoryFormState>(
      'sin subcategorías activas: Tipo queda editable',
      setUp: () {
        when(() => getCategory('root-1')).thenAnswer(
          (_) async => Right(buildCategory(id: 'root-1')),
        );
        when(() => getDeletionImpact('root-1')).thenAnswer(
          (_) async => const Right(
            CategoryDeletionImpact(
              hasActiveSubcategories: false,
              transactionCount: 0,
            ),
          ),
        );
      },
      build: build,
      act: (cubit) => cubit.load(id: 'root-1'),
      expect: () => [
        const CategoryFormState(),
        const CategoryFormState(
          status: CategoryFormStatus.ready,
          id: 'root-1',
          name: 'Comida',
        ),
      ],
    );

    blocTest<CategoryFormCubit, CategoryFormState>(
      'con subcategorías activas: Tipo queda bloqueado',
      setUp: () {
        when(() => getCategory('root-1')).thenAnswer(
          (_) async => Right(buildCategory(id: 'root-1')),
        );
        when(() => getDeletionImpact('root-1')).thenAnswer(
          (_) async => const Right(
            CategoryDeletionImpact(
              hasActiveSubcategories: true,
              transactionCount: 0,
            ),
          ),
        );
      },
      build: build,
      act: (cubit) => cubit.load(id: 'root-1'),
      verify: (cubit) {
        expect(
          cubit.state.kindLockReason,
          CategoryKindLockReason.rootWithSubcategories,
        );
        expect(cubit.state.kindLocked, isTrue);
      },
    );

    blocTest<CategoryFormCubit, CategoryFormState>(
      'kindSelected no cambia nada mientras el Tipo está bloqueado',
      setUp: () {
        when(() => getCategory('root-1')).thenAnswer(
          (_) async => Right(buildCategory(id: 'root-1')),
        );
        when(() => getDeletionImpact('root-1')).thenAnswer(
          (_) async => const Right(
            CategoryDeletionImpact(
              hasActiveSubcategories: true,
              transactionCount: 0,
            ),
          ),
        );
      },
      build: build,
      act: (cubit) async {
        await cubit.load(id: 'root-1');
        cubit.kindSelected(CategoryKind.income);
      },
      verify: (cubit) => expect(cubit.state.kind, CategoryKind.expense),
    );
  });

  group('caso 4: editar subcategoría', () {
    blocTest<CategoryFormCubit, CategoryFormState>(
      'Tipo bloqueado y campo padre resuelto por nombre',
      setUp: () {
        when(() => getCategory('sub-1')).thenAnswer(
          (_) async => Right(
            buildCategory(
              id: 'sub-1',
              name: 'Mercado',
              parentId: 'root-1',
            ),
          ),
        );
        when(() => getCategory('root-1')).thenAnswer(
          (_) async => Right(buildCategory(id: 'root-1')),
        );
      },
      build: build,
      act: (cubit) => cubit.load(id: 'sub-1'),
      expect: () => [
        const CategoryFormState(),
        const CategoryFormState(
          status: CategoryFormStatus.ready,
          id: 'sub-1',
          name: 'Mercado',
          parentId: 'root-1',
          parentName: 'Comida',
          kindLockReason: CategoryKindLockReason.subcategory,
        ),
      ],
    );
  });

  group('HU-04: borrado', () {
    blocTest<CategoryFormCubit, CategoryFormState>(
      'sin dependientes: prompt simple y confirmarlo hace soft delete',
      setUp: () {
        when(() => getDeletionImpact('root-1')).thenAnswer(
          (_) async => const Right(
            CategoryDeletionImpact(
              hasActiveSubcategories: false,
              transactionCount: 0,
            ),
          ),
        );
        when(
          () => deleteCategory(
            'root-1',
            transactionResolution: any(named: 'transactionResolution'),
            subcategoryResolution: any(named: 'subcategoryResolution'),
          ),
        ).thenAnswer((_) async => const Right(unit));
      },
      build: () {
        final cubit = build();
        return cubit;
      },
      seed: () => const CategoryFormState(
        status: CategoryFormStatus.ready,
        id: 'root-1',
      ),
      act: (cubit) async {
        await cubit.promptDelete();
        await cubit.confirmSimpleDelete();
      },
      verify: (cubit) {
        expect(cubit.state.status, CategoryFormStatus.saved);
        verify(() => deleteCategory('root-1')).called(1);
      },
    );

    blocTest<CategoryFormCubit, CategoryFormState>(
      'con transacciones: el prompt es transactions',
      setUp: () => when(() => getDeletionImpact('root-1')).thenAnswer(
        (_) async => const Right(
          CategoryDeletionImpact(
            hasActiveSubcategories: false,
            transactionCount: 3,
          ),
        ),
      ),
      build: build,
      seed: () => const CategoryFormState(
        status: CategoryFormStatus.ready,
        id: 'root-1',
      ),
      act: (cubit) => cubit.promptDelete(),
      verify: (cubit) =>
          expect(cubit.state.deletePrompt, CategoryDeletePrompt.transactions),
    );

    blocTest<CategoryFormCubit, CategoryFormState>(
      'raíz con subcategorías: el prompt es subcategories',
      setUp: () => when(() => getDeletionImpact('root-1')).thenAnswer(
        (_) async => const Right(
          CategoryDeletionImpact(
            hasActiveSubcategories: true,
            transactionCount: 0,
          ),
        ),
      ),
      build: build,
      seed: () => const CategoryFormState(
        status: CategoryFormStatus.ready,
        id: 'root-1',
      ),
      act: (cubit) => cubit.promptDelete(),
      verify: (cubit) => expect(
        cubit.state.deletePrompt,
        CategoryDeletePrompt.subcategories,
      ),
    );

    blocTest<CategoryFormCubit, CategoryFormState>(
      'caso combinado: transacciones resueltas encadenan a subcategorías, '
      'y solo entonces se borra con ambas resoluciones',
      setUp: () {
        when(() => getDeletionImpact('root-1')).thenAnswer(
          (_) async => const Right(
            CategoryDeletionImpact(
              hasActiveSubcategories: true,
              transactionCount: 2,
            ),
          ),
        );
        when(
          () => deleteCategory(
            'root-1',
            transactionResolution: any(named: 'transactionResolution'),
            subcategoryResolution: any(named: 'subcategoryResolution'),
          ),
        ).thenAnswer((_) async => const Right(unit));
      },
      build: build,
      seed: () => const CategoryFormState(
        status: CategoryFormStatus.ready,
        id: 'root-1',
      ),
      act: (cubit) async {
        await cubit.promptDelete();
        await cubit.confirmTransactionResolution(
          const TransactionResolution.clear(),
        );
        await cubit.confirmSubcategoryResolution(
          const SubcategoryResolution.cascade(),
        );
      },
      verify: (cubit) {
        expect(cubit.state.status, CategoryFormStatus.saved);
        verify(
          () => deleteCategory(
            'root-1',
            transactionResolution: const TransactionResolution.clear(),
            subcategoryResolution: const SubcategoryResolution.cascade(),
          ),
        ).called(1);
      },
    );

    blocTest<CategoryFormCubit, CategoryFormState>(
      'cancelar el prompt lo cierra sin borrar nada',
      setUp: () => when(() => getDeletionImpact('root-1')).thenAnswer(
        (_) async => const Right(
          CategoryDeletionImpact(
            hasActiveSubcategories: false,
            transactionCount: 0,
          ),
        ),
      ),
      build: build,
      seed: () => const CategoryFormState(
        status: CategoryFormStatus.ready,
        id: 'root-1',
      ),
      act: (cubit) async {
        await cubit.promptDelete();
        cubit.dismissDeletePrompt();
      },
      verify: (cubit) {
        expect(cubit.state.deletePrompt, CategoryDeletePrompt.none);
        verifyNever(
          () => deleteCategory(
            any(),
            transactionResolution: any(named: 'transactionResolution'),
            subcategoryResolution: any(named: 'subcategoryResolution'),
          ),
        );
      },
    );
  });
}
