import 'package:billetudo/core/error/result.dart';
import 'package:billetudo/features/categories/domain/entities/category.dart';
import 'package:billetudo/features/categories/domain/entities/category_node.dart';
import 'package:billetudo/features/categories/presentation/cubit/parent_category_picker_cubit.dart';
import 'package:billetudo/features/categories/presentation/cubit/parent_category_picker_state.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../domain/usecases/category_repository_mock.dart';
import '../usecase_mocks.dart';

void main() {
  late MockWatchParentCandidates watchParentCandidates;
  late MockWatchCategories watchCategories;

  final root1 = buildCategory(id: 'root-1');
  final root2 = buildCategory(id: 'root-2', name: 'Transporte');
  final sub1 = buildCategory(id: 'sub-1', name: 'Mercado', parentId: 'root-1');

  setUpAll(registerCategoryPresentationFallbacks);

  setUp(() {
    watchParentCandidates = MockWatchParentCandidates();
    watchCategories = MockWatchCategories();
  });

  ParentCategoryPickerCubit build() =>
      ParentCategoryPickerCubit(watchParentCandidates, watchCategories);

  blocTest<ParentCategoryPickerCubit, ParentCategoryPickerState>(
    'rootsOnly: true delega directo en WatchParentCandidates',
    setUp: () => when(
      () =>
          watchParentCandidates(any(), excludingId: any(named: 'excludingId')),
    ).thenAnswer((_) => Stream.value(Right([root1, root2]))),
    build: build,
    act: (cubit) => cubit.start(CategoryKind.expense, excludingId: 'root-3'),
    expect: () => [
      const ParentCategoryPickerState(),
      ParentCategoryPickerState(
        status: ParentCategoryPickerStatus.ready,
        candidates: [root1, root2],
      ),
    ],
  );

  blocTest<ParentCategoryPickerCubit, ParentCategoryPickerState>(
    'rootsOnly: false aplana raíz + subcategorías, excluyendo el id dado',
    setUp: () => when(() => watchCategories(any())).thenAnswer(
      (_) => Stream.value(
        Right([
          CategoryNode(root: root1, subcategories: [sub1]),
          CategoryNode(root: root2),
        ]),
      ),
    ),
    build: build,
    act: (cubit) => cubit.start(
      CategoryKind.expense,
      excludingId: 'root-2',
      rootsOnly: false,
    ),
    expect: () => [
      const ParentCategoryPickerState(),
      ParentCategoryPickerState(
        status: ParentCategoryPickerStatus.ready,
        candidates: [root1, sub1],
      ),
    ],
  );

  blocTest<ParentCategoryPickerCubit, ParentCategoryPickerState>(
    'un fallo del stream deja el estado de error',
    setUp: () => when(
      () =>
          watchParentCandidates(any(), excludingId: any(named: 'excludingId')),
    ).thenAnswer((_) => Stream.value(const Left(DatabaseFailure('boom')))),
    build: build,
    act: (cubit) => cubit.start(CategoryKind.expense),
    verify: (cubit) =>
        expect(cubit.state.status, ParentCategoryPickerStatus.failure),
  );
}
