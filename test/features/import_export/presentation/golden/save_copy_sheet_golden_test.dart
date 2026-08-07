import 'package:billetudo/core/error/failure.dart';
import 'package:billetudo/core/widgets/bottom_sheet_base.dart';
import 'package:billetudo/features/import_export/presentation/cubit/save_copy_cubit.dart';
import 'package:billetudo/features/import_export/presentation/cubit/save_copy_state.dart';
import 'package:billetudo/features/import_export/presentation/widgets/sheets/save_copy_sheet.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../support/golden_helpers.dart';

class MockSaveCopyCubit extends MockCubit<SaveCopyState> implements SaveCopyCubit {}

/// HU-03 "Guardar una copia", now a modal sheet (`SaveCopySheetBody`,
/// decision 2026-08-07) instead of a full page (`save_copy_page.dart`,
/// removed) — the whole flow is the shared progress/error pattern
/// (`d9wzVg`-pattern with `$teal`, `TmHSC`/`HbEJc`), which instances
/// `Bottom Sheet Base` (`PqTUt`) in `billetudo.pen`.
///
/// Rendered by wiring `SaveCopySheetBody` directly to a mocked cubit inside a
/// real `showModalBottomSheet` instead of going through `SaveCopySheet.show`/
/// `getIt`, same pattern `restore_sheet_golden_test.dart` follows.
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
    setGoldenViewport(tester, goldenPhoneSize);
    await tester.pumpWidget(
      wrapForGolden(
        Builder(
          builder: (context) => ElevatedButton(
            onPressed: () => showModalBottomSheet<void>(
              context: context,
              isScrollControlled: true,
              builder: (context) => BlocProvider<SaveCopyCubit>.value(
                value: cubit,
                child: const BottomSheetBase(child: SaveCopySheetBody()),
              ),
            ),
            child: const Text('open'),
          ),
        ),
        brightness: brightness,
      ),
    );
    await tester.tap(find.byType(ElevatedButton));
    if (settle) {
      await tester.pumpAndSettle();
    } else {
      await tester.pump();
    }
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/sheet_save_copy_$name.png'),
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
