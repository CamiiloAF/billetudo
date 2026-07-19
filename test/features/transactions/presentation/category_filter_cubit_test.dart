import 'dart:async';

import 'package:billetudo/core/error/result.dart';
import 'package:billetudo/features/categories/domain/entities/category.dart';
import 'package:billetudo/features/categories/domain/entities/category_node.dart';
import 'package:billetudo/features/transactions/presentation/cubit/category_filter_cubit.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'usecase_mocks.dart';

final DateTime _instant = DateTime(2026, 7, 15);

Category _category({
  required String id,
  String? parentId,
  CategoryKind kind = CategoryKind.expense,
}) =>
    Category(
      id: id,
      name: id,
      kind: kind,
      parentId: parentId,
      sortOrder: 0,
      createdAt: _instant,
      updatedAt: _instant.millisecondsSinceEpoch,
    );

void main() {
  late MockWatchCategories watchCategories;

  final root = _category(id: 'root');
  final sub1 = _category(id: 'sub-1', parentId: 'root');
  final sub2 = _category(id: 'sub-2', parentId: 'root');
  final node = CategoryNode(root: root, subcategories: [sub1, sub2]);

  setUpAll(registerPresentationFallbacks);

  setUp(() {
    watchCategories = MockWatchCategories();
    when(() => watchCategories(CategoryKind.expense))
        .thenAnswer((_) => Stream.value(Right([node])));
    when(() => watchCategories(CategoryKind.income))
        .thenAnswer((_) => Stream.value(const Right(<CategoryNode>[])));
  });

  CategoryFilterCubit build() => CategoryFilterCubit(watchCategories);

  blocTest<CategoryFilterCubit, CategoryFilterState>(
    'carga ambos árboles (ingreso y gasto)',
    build: build,
    act: (cubit) async {
      await cubit.start(const {});
      await Future<void>.delayed(Duration.zero);
    },
    verify: (cubit) => expect(cubit.state.expenseNodes, [node]),
  );

  blocTest<CategoryFilterCubit, CategoryFilterState>(
    'seleccionar una raíz selecciona su árbol completo (HU-06 toggle simétrico)',
    build: build,
    act: (cubit) async {
      await cubit.start(const {});
      cubit.toggleRootCategory(node);
    },
    verify: (cubit) => expect(cubit.state.selected, {'root', 'sub-1', 'sub-2'}),
  );

  blocTest<CategoryFilterCubit, CategoryFilterState>(
    'des-seleccionar la raíz limpia todo el árbol',
    build: build,
    act: (cubit) async {
      await cubit.start(const {});
      cubit.toggleRootCategory(node);
      cubit.toggleRootCategory(node);
    },
    verify: (cubit) => expect(cubit.state.selected, isEmpty),
  );

  blocTest<CategoryFilterCubit, CategoryFilterState>(
    'una subcategoría se alterna sola, sin arrastrar a su raíz ni hermanas',
    build: build,
    act: (cubit) async {
      await cubit.start(const {});
      cubit.toggleSubcategory('sub-1');
    },
    verify: (cubit) => expect(cubit.state.selected, {'sub-1'}),
  );

  blocTest<CategoryFilterCubit, CategoryFilterState>(
    'toggleExpanded abre y cierra una raíz de forma independiente',
    build: build,
    act: (cubit) async {
      await cubit.start(const {});
      cubit.toggleExpanded('root');
    },
    verify: (cubit) {
      expect(cubit.state.isExpanded('root'), isTrue);
      expect(cubit.state.isExpanded('other'), isFalse);
    },
  );

  blocTest<CategoryFilterCubit, CategoryFilterState>(
    'toggleExpanded llamado dos veces vuelve a colapsar',
    build: build,
    act: (cubit) async {
      await cubit.start(const {});
      cubit.toggleExpanded('root');
      cubit.toggleExpanded('root');
    },
    verify: (cubit) => expect(cubit.state.isExpanded('root'), isFalse),
  );

  blocTest<CategoryFilterCubit, CategoryFilterState>(
    'selectAll selecciona todo lo cargado en ambos árboles',
    build: build,
    act: (cubit) async {
      await cubit.start(const {});
      await Future<void>.delayed(Duration.zero);
      cubit.selectAll();
    },
    verify: (cubit) => expect(cubit.state.selected, {'root', 'sub-1', 'sub-2'}),
  );

  blocTest<CategoryFilterCubit, CategoryFilterState>(
    'selectNone limpia toda la selección',
    build: build,
    act: (cubit) async {
      await cubit.start(const {});
      await Future<void>.delayed(Duration.zero);
      cubit.selectAll();
      cubit.selectNone();
    },
    verify: (cubit) => expect(cubit.state.selected, isEmpty),
  );
}
