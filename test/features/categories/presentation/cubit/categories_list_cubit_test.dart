import 'dart:async';

import 'package:billetudo/core/error/result.dart';
import 'package:billetudo/features/categories/domain/entities/category.dart';
import 'package:billetudo/features/categories/domain/entities/category_node.dart';
import 'package:billetudo/features/categories/presentation/cubit/categories_list_cubit.dart';
import 'package:billetudo/features/categories/presentation/cubit/categories_list_state.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../domain/usecases/category_repository_mock.dart';
import '../usecase_mocks.dart';

void main() {
  late MockWatchCategories watchCategories;
  late MockReorderCategories reorderCategories;

  final food = buildCategory(id: 'food');
  final transport =
      buildCategory(id: 'transport', name: 'Transporte', sortOrder: 1);
  final nodes = [
    CategoryNode(root: food),
    CategoryNode(root: transport),
  ];

  setUpAll(registerCategoryPresentationFallbacks);

  setUp(() {
    watchCategories = MockWatchCategories();
    reorderCategories = MockReorderCategories();
  });

  CategoriesListCubit build() =>
      CategoriesListCubit(watchCategories, reorderCategories);

  // Builds a *fresh* stream on every call: `watchCategories` gets invoked
  // once per kind (and again on retry), and a `Stream.value` can only be
  // listened to once — the cubit unsubscribes from the old kind and
  // subscribes to the new one, so each call needs its own stream instance.
  void stub(Result<List<CategoryNode>> Function() value) {
    when(() => watchCategories(any())).thenAnswer((_) => Stream.value(value()));
  }

  void stubOnce(Result<List<CategoryNode>> result) => stub(() => result);

  group('carga inicial', () {
    blocTest<CategoriesListCubit, CategoriesListState>(
      'emite los nodos cuando llegan del stream',
      setUp: () => stubOnce(Right(nodes)),
      build: build,
      act: (cubit) => cubit.start(),
      expect: () => [
        const CategoriesListState(),
        CategoriesListState(
          status: CategoriesListStatus.ready,
          nodes: nodes,
        ),
      ],
    );

    blocTest<CategoriesListCubit, CategoriesListState>(
      'una lista vacía queda en ready: isEmpty es su propio estado',
      setUp: () => stubOnce(const Right(<CategoryNode>[])),
      build: build,
      act: (cubit) => cubit.start(),
      verify: (cubit) {
        expect(cubit.state.isEmpty, isTrue);
        expect(cubit.state.isLoading, isFalse);
      },
    );

    blocTest<CategoriesListCubit, CategoriesListState>(
      'un fallo del stream deja el estado de error',
      setUp: () => stubOnce(const Left(DatabaseFailure('boom'))),
      build: build,
      act: (cubit) => cubit.start(),
      verify: (cubit) {
        expect(cubit.state.status, CategoriesListStatus.failure);
        expect(cubit.state.failure, isA<DatabaseFailure>());
      },
    );
  });

  group('toggle Gasto/Ingreso', () {
    blocTest<CategoriesListCubit, CategoriesListState>(
      'cambiar de kind resuscribe al stream del nuevo kind',
      setUp: () => stubOnce(Right(nodes)),
      build: build,
      act: (cubit) async {
        await cubit.start();
        await Future<void>.delayed(Duration.zero);
        await cubit.selectKind(CategoryKind.income);
      },
      verify: (cubit) {
        expect(cubit.state.kind, CategoryKind.income);
        verify(() => watchCategories(CategoryKind.expense)).called(1);
        verify(() => watchCategories(CategoryKind.income)).called(1);
      },
    );

    blocTest<CategoriesListCubit, CategoriesListState>(
      'seleccionar el mismo kind activo no hace nada',
      setUp: () => stubOnce(Right(nodes)),
      build: build,
      act: (cubit) async {
        await cubit.start();
        await Future<void>.delayed(Duration.zero);
        await cubit.selectKind(CategoryKind.expense);
      },
      verify: (_) => verify(() => watchCategories(any())).called(1),
    );
  });

  group('expandir/colapsar', () {
    blocTest<CategoriesListCubit, CategoriesListState>(
      'toggleExpanded agrega y quita el id del set de expandidos',
      setUp: () => stubOnce(Right(nodes)),
      build: build,
      act: (cubit) async {
        await cubit.start();
        await Future<void>.delayed(Duration.zero);
        cubit.toggleExpanded('food');
      },
      verify: (cubit) => expect(cubit.state.isExpanded('food'), isTrue),
    );

    blocTest<CategoriesListCubit, CategoriesListState>(
      'toggleExpanded dos veces vuelve a colapsar la fila',
      setUp: () => stubOnce(Right(nodes)),
      build: build,
      act: (cubit) async {
        await cubit.start();
        await Future<void>.delayed(Duration.zero);
        cubit.toggleExpanded('food');
        cubit.toggleExpanded('food');
      },
      verify: (cubit) => expect(cubit.state.isExpanded('food'), isFalse),
    );
  });

  group('reordenar (HU-05)', () {
    blocTest<CategoriesListCubit, CategoriesListState>(
      'persiste el nuevo orden de ids y lo refleja de inmediato',
      setUp: () {
        stubOnce(Right(nodes));
        when(() => reorderCategories(any()))
            .thenAnswer((_) async => const Right(unit));
      },
      build: build,
      act: (cubit) async {
        await cubit.start();
        await Future<void>.delayed(Duration.zero);
        await cubit.reorder(0, 2);
      },
      verify: (cubit) {
        expect(
          [for (final node in cubit.state.nodes) node.root.id],
          ['transport', 'food'],
        );
        verify(() => reorderCategories(['transport', 'food'])).called(1);
      },
    );

    blocTest<CategoriesListCubit, CategoriesListState>(
      'soltar la fila en su misma posición no escribe nada',
      setUp: () => stubOnce(Right(nodes)),
      build: build,
      act: (cubit) async {
        await cubit.start();
        await Future<void>.delayed(Duration.zero);
        await cubit.reorder(1, 1);
      },
      verify: (_) => verifyNever(() => reorderCategories(any())),
    );

    blocTest<CategoriesListCubit, CategoriesListState>(
      'si la escritura falla, el error queda visible',
      setUp: () {
        stubOnce(Right(nodes));
        when(() => reorderCategories(any()))
            .thenAnswer((_) async => const Left(DatabaseFailure('boom')));
      },
      build: build,
      act: (cubit) async {
        await cubit.start();
        await Future<void>.delayed(Duration.zero);
        await cubit.reorder(0, 2);
      },
      verify: (cubit) =>
          expect(cubit.state.status, CategoriesListStatus.failure),
    );
  });

  test('cerrar el cubit cancela la suscripción al stream', () async {
    final controller = StreamController<Result<List<CategoryNode>>>.broadcast();
    when(() => watchCategories(any())).thenAnswer((_) => controller.stream);

    final cubit = build();
    await cubit.start();
    await cubit.close();

    expect(controller.hasListener, isFalse);
    await controller.close();
  });
}
