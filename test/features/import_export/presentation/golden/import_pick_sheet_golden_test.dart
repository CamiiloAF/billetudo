import 'package:billetudo/core/widgets/bottom_sheet_base.dart';
import 'package:billetudo/features/import_export/presentation/cubit/import_flow_cubit.dart';
import 'package:billetudo/features/import_export/presentation/cubit/import_flow_state.dart';
import 'package:billetudo/features/import_export/presentation/widgets/sheets/import_pick_sheet.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../support/golden_helpers.dart';

class MockImportFlowCubit extends MockCubit<ImportFlowState> implements ImportFlowCubit {}

/// HU-09's initial file-parse error (`a5XdP`/`qWIvy`), now a modal sheet
/// (`ImportPickErrorSheetBody`, decision 2026-08-07) instead of rendering
/// inline on `ImportFlowPage`. Rendered the same way
/// `restore_sheet_golden_test.dart` renders `RestoreSheetBody`: wired
/// directly to a mocked cubit inside a real `showModalBottomSheet`, not
/// through `ImportPickSheet.show`/`getIt` (neither the DI container nor the
/// native file picker have any reason to be part of a golden test).
void main() {
  late MockImportFlowCubit cubit;

  setUpAll(() async {
    disableGoogleFontsRuntimeFetching();
    await loadMaterialIconsFont();
  });

  setUp(() {
    cubit = MockImportFlowCubit();
    when(() => cubit.state).thenReturn(const ImportFlowState(runStatus: ImportFlowRunStatus.error));
  });

  Future<void> golden(WidgetTester tester, String name, {required Brightness brightness}) async {
    setGoldenViewport(tester, goldenPhoneSize);
    await tester.pumpWidget(
      wrapForGolden(
        Builder(
          builder: (context) => ElevatedButton(
            onPressed: () => showModalBottomSheet<void>(
              context: context,
              isScrollControlled: true,
              builder: (context) => BlocProvider<ImportFlowCubit>.value(
                value: cubit,
                child: BottomSheetBase(
                  child: ImportPickErrorSheetBody(onDismissed: () => Navigator.of(context).pop()),
                ),
              ),
            ),
            child: const Text('open'),
          ),
        ),
        brightness: brightness,
      ),
    );
    await tester.tap(find.byType(ElevatedButton));
    await tester.pumpAndSettle();
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/sheet_import_pick_$name.png'),
    );
  }

  for (final brightness in Brightness.values) {
    final suffix = brightness == Brightness.light ? 'light' : 'dark';

    testWidgets('unreadable file error ($suffix)', (tester) async {
      await golden(tester, 'error_unreadable_$suffix', brightness: brightness);
    });
  }
}
