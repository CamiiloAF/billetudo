import 'package:billetudo/features/categories/domain/entities/category_node.dart';
import 'package:billetudo/features/categories/presentation/cubit/categories_list_cubit.dart';
import 'package:billetudo/features/categories/presentation/cubit/categories_list_state.dart';
import 'package:billetudo/features/categories/presentation/pages/categories_page.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../domain/usecases/category_repository_mock.dart';
import 'golden_helpers.dart';

class MockCategoriesListCubit extends MockCubit<CategoriesListState>
    implements CategoriesListCubit {}

void main() {
  late MockCategoriesListCubit cubit;

  final nodes = [
    CategoryNode(
      root: buildCategory(
        id: 'root-1',
        icon: 'utensils',
        color: 'coral',
      ),
      subcategories: [
        buildCategory(
          id: 'sub-1',
          name: 'Restaurantes',
          parentId: 'root-1',
          icon: 'utensils',
          color: 'coral',
        ),
        buildCategory(
          id: 'sub-2',
          name: 'Mercado',
          parentId: 'root-1',
          icon: 'banknote',
          color: 'mint',
        ),
      ],
    ),
    CategoryNode(
      root: buildCategory(
        id: 'root-2',
        name: 'Transporte',
        sortOrder: 1,
        icon: 'car',
        color: 'sky',
      ),
    ),
  ];

  setUpAll(() async {
    disableGoogleFontsRuntimeFetching();
    await loadMaterialIconsFont();
  });
  setUp(() => cubit = MockCategoriesListCubit());

  Future<void> golden(
    WidgetTester tester,
    CategoriesListState state,
    String name, {
    required Brightness brightness,
  }) async {
    when(() => cubit.state).thenReturn(state);
    await pumpGolden(
      tester,
      BlocProvider<CategoriesListCubit>.value(
        value: cubit,
        child: CategoriesPage(
          onAddCategory: (_) {},
          onAddSubcategory: (_) {},
          onOpenCategory: (_) {},
        ),
      ),
      brightness: brightness,
      size: tallGoldenPhoneSize,
    );
    await expectLater(
      find.byType(CategoriesPage),
      matchesGoldenFile('goldens/categories_page_$name.png'),
    );
  }

  for (final brightness in Brightness.values) {
    final suffix = brightness == Brightness.light ? 'light' : 'dark';

    testWidgets('loading ($suffix)', (tester) async {
      await golden(
        tester,
        const CategoriesListState(),
        'loading_$suffix',
        brightness: brightness,
      );
    });

    testWidgets('empty ($suffix)', (tester) async {
      await golden(
        tester,
        const CategoriesListState(status: CategoriesListStatus.ready),
        'empty_$suffix',
        brightness: brightness,
      );
    });

    testWidgets('error ($suffix)', (tester) async {
      await golden(
        tester,
        const CategoriesListState(status: CategoriesListStatus.failure),
        'error_$suffix',
        brightness: brightness,
      );
    });

    testWidgets('with data: one root expanded, one collapsed ($suffix)',
        (tester) async {
      await golden(
        tester,
        CategoriesListState(
          status: CategoriesListStatus.ready,
          nodes: nodes,
          expandedRootIds: const {'root-1'},
        ),
        'with_data_$suffix',
        brightness: brightness,
      );
    });
  }
}
