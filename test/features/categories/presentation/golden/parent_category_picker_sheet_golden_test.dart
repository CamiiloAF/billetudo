import 'package:billetudo/core/widgets/bottom_sheet_base.dart';
import 'package:billetudo/features/categories/presentation/cubit/parent_category_picker_cubit.dart';
import 'package:billetudo/features/categories/presentation/cubit/parent_category_picker_state.dart';
import 'package:billetudo/features/categories/presentation/widgets/parent_category_picker_sheet.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../support/golden_helpers.dart';
import '../../domain/usecases/category_repository_mock.dart';

class MockParentCategoryPickerCubit extends MockCubit<ParentCategoryPickerState>
    implements ParentCategoryPickerCubit {}

/// `ParentCategoryPickerSheet` (the `StatelessWidget` that resolves its cubit
/// through `getIt`, see its own doc comment) is not exercised directly here —
/// same reason `icon_color_picker_sheet_golden_test.dart` skips it, standing
/// up the feature's DI graph just for a golden is not worth it. But its body,
/// `ParentCategoryPickerSheetBody`, takes no such dependency: it only reads a
/// `ParentCategoryPickerCubit` from the widget tree, so a mocked one (same
/// pattern `categories_page_golden_test.dart` uses for
/// `CategoriesListCubit`) is enough to golden every state of the picker
/// (`Q55fEz`) without DI.
void main() {
  late MockParentCategoryPickerCubit cubit;

  final candidates = [
    buildCategory(
        id: 'root-1', name: 'Comida', icon: 'utensils-crossed', color: 'coral'),
    buildCategory(id: 'root-2', name: 'Transporte', icon: 'car', color: 'sky'),
    buildCategory(id: 'root-3', name: 'Hogar', icon: 'house', color: 'mint'),
  ];

  setUpAll(() async {
    disableGoogleFontsRuntimeFetching();
    await loadMaterialIconsFont();
  });
  setUp(() => cubit = MockParentCategoryPickerCubit());

  Future<void> golden(
    WidgetTester tester,
    ParentCategoryPickerState state,
    String name, {
    required Brightness brightness,
  }) async {
    when(() => cubit.state).thenReturn(state);
    setGoldenViewport(tester);
    await tester.pumpWidget(
      wrapForGolden(
        Builder(
          builder: (context) => ElevatedButton(
            onPressed: () => BottomSheetBase.show<void>(
              context,
              builder: (context) =>
                  BlocProvider<ParentCategoryPickerCubit>.value(
                value: cubit,
                child: const ParentCategoryPickerSheetBody(),
              ),
            ),
            child: const Text('open'),
          ),
        ),
        brightness: brightness,
      ),
    );
    await tester.tap(find.byType(ElevatedButton));
    if (state.isLoading) {
      // The loading state renders an indeterminate `CircularProgressIndicator`
      // (see `pumpGolden`'s own `settle` doc): its `AnimationController`
      // repeats forever, so `pumpAndSettle` never finishes. A couple of
      // fixed-duration pumps still settles the sheet's open transition and
      // captures a deterministic spinner frame.
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
    } else {
      await tester.pumpAndSettle();
    }
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/sheet_parent_category_picker_$name.png'),
    );
  }

  for (final brightness in Brightness.values) {
    final suffix = brightness == Brightness.light ? 'light' : 'dark';

    testWidgets('loading ($suffix)', (tester) async {
      await golden(
        tester,
        const ParentCategoryPickerState(),
        'loading_$suffix',
        brightness: brightness,
      );
    });

    testWidgets('empty, no candidates ($suffix)', (tester) async {
      await golden(
        tester,
        const ParentCategoryPickerState(
            status: ParentCategoryPickerStatus.ready),
        'empty_$suffix',
        brightness: brightness,
      );
    });

    testWidgets('with candidates, none selected ($suffix)', (tester) async {
      await golden(
        tester,
        ParentCategoryPickerState(
          status: ParentCategoryPickerStatus.ready,
          candidates: candidates,
        ),
        'unselected_$suffix',
        brightness: brightness,
      );
    });

    testWidgets('with candidates, one selected ($suffix)', (tester) async {
      await golden(
        tester,
        ParentCategoryPickerState(
          status: ParentCategoryPickerStatus.ready,
          candidates: candidates,
          selectedId: 'root-2',
        ),
        'selected_$suffix',
        brightness: brightness,
      );
    });
  }
}
