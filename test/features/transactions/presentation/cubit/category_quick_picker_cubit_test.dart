import 'package:billetudo/core/error/result.dart';
import 'package:billetudo/features/categories/domain/entities/category.dart';
import 'package:billetudo/features/categories/domain/usecases/get_category.dart';
import 'package:billetudo/features/categories/domain/usecases/get_most_used_categories.dart';
import 'package:billetudo/features/transactions/presentation/cubit/category_quick_picker_cubit.dart';
import 'package:billetudo/features/transactions/presentation/cubit/category_quick_picker_state.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockGetMostUsedCategories extends Mock
    implements GetMostUsedCategories {}

class _MockGetCategory extends Mock implements GetCategory {}

Category _category({
  String id = 'cat-1',
  String name = 'Comida',
  CategoryKind kind = CategoryKind.expense,
}) {
  final now = DateTime(2026, 7, 15);
  return Category(
    id: id,
    name: name,
    kind: kind,
    sortOrder: 0,
    createdAt: now,
    updatedAt: now.millisecondsSinceEpoch,
  );
}

void main() {
  late _MockGetMostUsedCategories getMostUsedCategories;
  late _MockGetCategory getCategory;

  setUpAll(() => registerFallbackValue(CategoryKind.expense));

  setUp(() {
    getMostUsedCategories = _MockGetMostUsedCategories();
    getCategory = _MockGetCategory();
  });

  CategoryQuickPickerCubit build() =>
      CategoryQuickPickerCubit(getMostUsedCategories, getCategory);

  blocTest<CategoryQuickPickerCubit, CategoryQuickPickerState>(
    'start carga las más usadas y queda en ready',
    setUp: () {
      when(
        () => getMostUsedCategories(
          any(),
          limit: any(named: 'limit'),
          accountId: any(named: 'accountId'),
        ),
      ).thenAnswer((_) async => Right([_category()]));
    },
    build: build,
    act: (cubit) => cubit.start(kind: CategoryKind.expense),
    verify: (cubit) {
      expect(cubit.state.status, CategoryQuickPickerStatus.ready);
      expect(cubit.state.mostUsed.map((c) => c.id), ['cat-1']);
      expect(cubit.state.selected, isNull);
    },
  );

  blocTest<CategoryQuickPickerCubit, CategoryQuickPickerState>(
    'start resuelve una selección que ya está entre las más usadas sin '
    'llamar a getCategory',
    setUp: () {
      when(
        () => getMostUsedCategories(
          any(),
          limit: any(named: 'limit'),
          accountId: any(named: 'accountId'),
        ),
      ).thenAnswer((_) async => Right([_category()]));
    },
    build: build,
    act: (cubit) =>
        cubit.start(kind: CategoryKind.expense, selectedId: 'cat-1'),
    verify: (cubit) {
      expect(cubit.state.selected?.id, 'cat-1');
      verifyNever(() => getCategory(any()));
    },
  );

  blocTest<CategoryQuickPickerCubit, CategoryQuickPickerState>(
    'caso borde: una selección fuera del top-3 se resuelve vía getCategory '
    'y se muestra como chip adicional',
    setUp: () {
      when(
        () => getMostUsedCategories(
          any(),
          limit: any(named: 'limit'),
          accountId: any(named: 'accountId'),
        ),
      ).thenAnswer((_) async => Right([_category()]));
      when(() => getCategory('cat-99')).thenAnswer(
        (_) async => Right(_category(id: 'cat-99', name: 'Regalos')),
      );
    },
    build: build,
    act: (cubit) =>
        cubit.start(kind: CategoryKind.expense, selectedId: 'cat-99'),
    verify: (cubit) {
      expect(cubit.state.selected?.id, 'cat-99');
      // The out-of-top-3 selection is prepended as an extra chip.
      expect(
        cubit.state.displayCategories.map((c) => c.id),
        ['cat-99', 'cat-1'],
      );
      verify(() => getCategory('cat-99')).called(1);
    },
  );

  blocTest<CategoryQuickPickerCubit, CategoryQuickPickerState>(
    'select fija la categoría elegida',
    setUp: () {
      when(
        () => getMostUsedCategories(
          any(),
          limit: any(named: 'limit'),
          accountId: any(named: 'accountId'),
        ),
      ).thenAnswer((_) async => const Right(<Category>[]));
    },
    build: build,
    act: (cubit) async {
      await cubit.start(kind: CategoryKind.expense);
      cubit.select(_category(id: 'cat-7', name: 'Café'));
    },
    verify: (cubit) => expect(cubit.state.selected?.id, 'cat-7'),
  );

  blocTest<CategoryQuickPickerCubit, CategoryQuickPickerState>(
    'setKind recarga las más usadas del nuevo kind',
    setUp: () {
      when(
        () => getMostUsedCategories(
          CategoryKind.expense,
          limit: any(named: 'limit'),
          accountId: any(named: 'accountId'),
        ),
      ).thenAnswer((_) async => Right([_category()]));
      when(
        () => getMostUsedCategories(
          CategoryKind.income,
          limit: any(named: 'limit'),
          accountId: any(named: 'accountId'),
        ),
      ).thenAnswer(
        (_) async => Right([_category(id: 'inc-1', name: 'Salario')]),
      );
    },
    build: build,
    act: (cubit) async {
      await cubit.start(kind: CategoryKind.expense);
      await cubit.setKind(CategoryKind.income);
    },
    verify: (cubit) => expect(cubit.state.mostUsed.map((c) => c.id), ['inc-1']),
  );

  blocTest<CategoryQuickPickerCubit, CategoryQuickPickerState>(
    'setAccount recarga las más usadas cuando el accountId cambió',
    setUp: () {
      when(
        () => getMostUsedCategories(
          CategoryKind.expense,
          limit: any(named: 'limit'),
          accountId: null,
        ),
      ).thenAnswer((_) async => Right([_category()]));
      when(
        () => getMostUsedCategories(
          CategoryKind.expense,
          limit: any(named: 'limit'),
          accountId: 'account-2',
        ),
      ).thenAnswer(
        (_) async => Right([_category(id: 'cat-2', name: 'Transporte')]),
      );
    },
    build: build,
    act: (cubit) async {
      await cubit.start(kind: CategoryKind.expense);
      await cubit.setAccount('account-2');
    },
    verify: (cubit) {
      expect(cubit.state.mostUsed.map((c) => c.id), ['cat-2']);
      verify(
        () => getMostUsedCategories(
          CategoryKind.expense,
          limit: any(named: 'limit'),
          accountId: 'account-2',
        ),
      ).called(1);
    },
  );

  blocTest<CategoryQuickPickerCubit, CategoryQuickPickerState>(
    'setAccount es un no-op cuando el accountId no cambió',
    setUp: () {
      when(
        () => getMostUsedCategories(
          CategoryKind.expense,
          limit: any(named: 'limit'),
          accountId: 'account-1',
        ),
      ).thenAnswer((_) async => Right([_category()]));
    },
    build: build,
    act: (cubit) async {
      await cubit.start(kind: CategoryKind.expense, accountId: 'account-1');
      await cubit.setAccount('account-1');
    },
    verify: (cubit) {
      verify(
        () => getMostUsedCategories(
          CategoryKind.expense,
          limit: any(named: 'limit'),
          accountId: 'account-1',
        ),
      ).called(1);
    },
  );

  blocTest<CategoryQuickPickerCubit, CategoryQuickPickerState>(
    'la selección sobrevive a un cambio de cuenta vía setAccount',
    setUp: () {
      when(
        () => getMostUsedCategories(
          CategoryKind.expense,
          limit: any(named: 'limit'),
          accountId: null,
        ),
      ).thenAnswer((_) async => Right([_category()]));
      when(
        () => getMostUsedCategories(
          CategoryKind.expense,
          limit: any(named: 'limit'),
          accountId: 'account-2',
        ),
      ).thenAnswer(
        (_) async => Right([_category(id: 'cat-2', name: 'Transporte')]),
      );
    },
    build: build,
    act: (cubit) async {
      await cubit.start(kind: CategoryKind.expense);
      cubit.select(_category(id: 'cat-7', name: 'Café'));
      await cubit.setAccount('account-2');
    },
    verify: (cubit) {
      expect(cubit.state.selected?.id, 'cat-7');
      expect(cubit.state.mostUsed.map((c) => c.id), ['cat-2']);
    },
  );
}
