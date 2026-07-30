import 'package:billetudo/core/error/failure.dart';
import 'package:billetudo/features/import_export/presentation/cubit/save_copy_cubit.dart';
import 'package:billetudo/features/import_export/presentation/cubit/save_copy_state.dart';
import 'package:billetudo/features/import_export/presentation/pages/save_copy_page.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../support/golden_helpers.dart';

class MockSaveCopyCubit extends MockCubit<SaveCopyState> implements SaveCopyCubit {}

void main() {
  late MockSaveCopyCubit cubit;

  setUpAll(() async {
    disableGoogleFontsRuntimeFetching();
    await loadMaterialIconsFont();
  });
  setUp(() => cubit = MockSaveCopyCubit());

  Future<void> golden(
    WidgetTester tester,
    SaveCopyState state,
    String name, {
    required Brightness brightness,
    bool settle = true,
  }) async {
    when(() => cubit.state).thenReturn(state);
    await pumpGolden(
      tester,
      BlocProvider<SaveCopyCubit>.value(
        value: cubit,
        child: SaveCopyPage(onDone: () {}),
      ),
      brightness: brightness,
      settle: settle,
    );
    await expectLater(
      find.byType(SaveCopyPage),
      matchesGoldenFile('goldens/save_copy_page_$name.png'),
    );
  }

  for (final brightness in Brightness.values) {
    final suffix = brightness == Brightness.light ? 'light' : 'dark';

    testWidgets('running, progress ($suffix)', (tester) async {
      await golden(
        tester,
        const SaveCopyState(status: SaveCopyStatus.running, processed: 5, total: 9),
        'progress_$suffix',
        brightness: brightness,
        settle: false,
      );
    });

    testWidgets('write failure ($suffix)', (tester) async {
      await golden(
        tester,
        const SaveCopyState(status: SaveCopyStatus.error, failure: IoFailure('boom')),
        'error_$suffix',
        brightness: brightness,
      );
    });
  }
}
