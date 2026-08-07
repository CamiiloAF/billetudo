import 'package:billetudo/core/error/failure.dart';
import 'package:billetudo/core/widgets/bottom_sheet_base.dart';
import 'package:billetudo/features/import_export/presentation/cubit/export_cubit.dart';
import 'package:billetudo/features/import_export/presentation/cubit/export_state.dart';
import 'package:billetudo/features/import_export/presentation/widgets/sheets/export_run_sheet.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../support/golden_helpers.dart';

class MockExportCubit extends MockCubit<ExportState> implements ExportCubit {}

/// HU-01/HU-02/HU-09's export write, now a modal sheet (`ExportRunSheetBody`,
/// decision 2026-08-07) instead of rendering inline on `ExportPage` — `xdG9q`/
/// `dSkbx` (progress) and `TmHSC`/`HbEJc` (write failure) instance
/// `Bottom Sheet Base` (`PqTUt`) in `billetudo.pen`. `ExportPage`'s scope
/// form keeps its own `Page Header` page, unchanged.
///
/// Rendered by wiring `ExportRunSheetBody` directly to a mocked cubit inside
/// a real `showModalBottomSheet` instead of going through
/// `ExportRunSheet.show`, same pattern `restore_sheet_golden_test.dart`
/// follows.
void main() {
  late MockExportCubit cubit;

  setUpAll(() async {
    disableGoogleFontsRuntimeFetching();
    await loadMaterialIconsFont();
  });

  setUp(() => cubit = MockExportCubit());

  Future<void> golden(
    WidgetTester tester,
    ExportState state,
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
              builder: (context) => BlocProvider<ExportCubit>.value(
                value: cubit,
                child: const BottomSheetBase(child: ExportRunSheetBody()),
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
      matchesGoldenFile('goldens/sheet_export_run_$name.png'),
    );
  }

  for (final brightness in Brightness.values) {
    final suffix = brightness == Brightness.light ? 'light' : 'dark';

    testWidgets('running, progress ($suffix)', (tester) async {
      await golden(
        tester,
        const ExportState(
          runStatus: ExportRunStatus.running,
          processed: 420,
          total: 1200,
        ),
        'progress_$suffix',
        brightness: brightness,
        settle: false,
      );
    });

    testWidgets('write failure ($suffix)', (tester) async {
      await golden(
        tester,
        const ExportState(runStatus: ExportRunStatus.error, failure: IoFailure('boom')),
        'error_$suffix',
        brightness: brightness,
      );
    });
  }
}
