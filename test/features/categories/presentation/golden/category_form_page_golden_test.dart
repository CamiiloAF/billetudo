import 'package:billetudo/features/categories/presentation/cubit/category_form_cubit.dart';
import 'package:billetudo/features/categories/presentation/cubit/category_form_state.dart';
import 'package:billetudo/features/categories/presentation/pages/category_form_page.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'golden_helpers.dart';

class MockCategoryFormCubit extends MockCubit<CategoryFormState>
    implements CategoryFormCubit {}

void main() {
  late MockCategoryFormCubit cubit;

  setUpAll(() async {
    disableGoogleFontsRuntimeFetching();
    await loadMaterialIconsFont();
  });
  setUp(() => cubit = MockCategoryFormCubit());

  Future<void> golden(
    WidgetTester tester,
    CategoryFormState state,
    String name, {
    required Brightness brightness,
  }) async {
    when(() => cubit.state).thenReturn(state);
    await pumpGolden(
      tester,
      BlocProvider<CategoryFormCubit>.value(
        value: cubit,
        child: const CategoryFormPage(),
      ),
      brightness: brightness,
      size: tallGoldenPhoneSize,
    );
    await expectLater(
      find.byType(CategoryFormPage),
      matchesGoldenFile('goldens/category_form_page_$name.png'),
    );
  }

  for (final brightness in Brightness.values) {
    final suffix = brightness == Brightness.light ? 'light' : 'dark';

    testWidgets('create root ($suffix)', (tester) async {
      await golden(
        tester,
        const CategoryFormState(status: CategoryFormStatus.ready),
        'create_root_$suffix',
        brightness: brightness,
      );
    });

    testWidgets('create subcategory, parent prefilled and locked ($suffix)',
        (tester) async {
      await golden(
        tester,
        const CategoryFormState(
          status: CategoryFormStatus.ready,
          parentId: 'root-1',
          parentName: 'Comida',
          kindLockReason: CategoryKindLockReason.subcategory,
        ),
        'create_subcategory_$suffix',
        brightness: brightness,
      );
    });

    testWidgets('edit root ($suffix)', (tester) async {
      await golden(
        tester,
        const CategoryFormState(
          status: CategoryFormStatus.ready,
          id: 'root-1',
          name: 'Transporte',
          icon: 'car',
          color: 'sky',
        ),
        'edit_root_$suffix',
        brightness: brightness,
      );
    });

    testWidgets('edit subcategory, Tipo locked ($suffix)', (tester) async {
      await golden(
        tester,
        const CategoryFormState(
          status: CategoryFormStatus.ready,
          id: 'sub-1',
          parentId: 'root-1',
          parentName: 'Comida',
          name: 'Restaurantes',
          icon: 'utensils',
          color: 'coral',
          kindLockReason: CategoryKindLockReason.subcategory,
        ),
        'edit_subcategory_$suffix',
        brightness: brightness,
      );
    });
  }
}
