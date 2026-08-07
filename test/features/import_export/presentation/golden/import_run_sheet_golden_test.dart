import 'package:billetudo/core/widgets/bottom_sheet_base.dart';
import 'package:billetudo/features/import_export/domain/entities/import_batch.dart';
import 'package:billetudo/features/import_export/domain/entities/import_summary.dart';
import 'package:billetudo/features/import_export/presentation/cubit/import_flow_cubit.dart';
import 'package:billetudo/features/import_export/presentation/cubit/import_flow_state.dart';
import 'package:billetudo/features/import_export/presentation/widgets/sheets/import_run_sheet.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../support/golden_helpers.dart';

class MockImportFlowCubit extends MockCubit<ImportFlowState> implements ImportFlowCubit {}

/// HU-05/06/09's final commit and what follows it, now a modal sheet
/// (`ImportRunSheetBody`, decision 2026-08-07) instead of rendering inline on
/// `ImportFlowPage` — `d9wzVg`/`VHJP8` (progress), `TmHSC`/`HbEJc` (write
/// failure) and `Aa1ek`/`XRBVa` (closing summary) all instance
/// `Bottom Sheet Base` (`PqTUt`) in `billetudo.pen`. The mapping/
/// destinations/preview wizard steps keep their own `Page Header` pages,
/// unchanged.
///
/// Rendered by wiring `ImportRunSheetBody` directly to a mocked cubit inside
/// a real `showModalBottomSheet` instead of going through
/// `ImportRunSheet.show`, same pattern `restore_sheet_golden_test.dart`
/// follows.
void main() {
  late MockImportFlowCubit cubit;

  final summary = ImportSummary(
    batch: ImportBatch(
      id: 'batch-1',
      fileName: 'movimientos-banco.csv',
      importedAt: DateTime(2026, 7, 1),
      rowsImported: 40,
      rowsSkipped: 2,
      createdAt: DateTime(2026, 7, 1),
      updatedAt: 0,
    ),
    rowsImported: 40,
    rowsSkippedDuplicate: 1,
    rowsSkippedError: 1,
    accountsCreated: 1,
    categoriesCreated: 2,
    tagsCreated: 0,
  );

  setUpAll(() async {
    disableGoogleFontsRuntimeFetching();
    await loadMaterialIconsFont();
  });

  setUp(() => cubit = MockImportFlowCubit());

  Future<void> golden(
    WidgetTester tester,
    ImportFlowState state,
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
              builder: (context) => BlocProvider<ImportFlowCubit>.value(
                value: cubit,
                child: BottomSheetBase(child: ImportRunSheetBody(onDone: () {})),
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
      matchesGoldenFile('goldens/sheet_import_run_$name.png'),
    );
  }

  for (final brightness in Brightness.values) {
    final suffix = brightness == Brightness.light ? 'light' : 'dark';

    testWidgets('importing, blocking progress ($suffix)', (tester) async {
      await golden(
        tester,
        const ImportFlowState(
          step: ImportFlowStep.preview,
          runStatus: ImportFlowRunStatus.committing,
          processed: 25,
          total: 40,
        ),
        'progress_$suffix',
        brightness: brightness,
        settle: false,
      );
    });

    testWidgets('write failure ($suffix)', (tester) async {
      await golden(
        tester,
        const ImportFlowState(
          step: ImportFlowStep.preview,
          runStatus: ImportFlowRunStatus.error,
        ),
        'error_$suffix',
        brightness: brightness,
      );
    });

    testWidgets('final summary ($suffix)', (tester) async {
      await golden(
        tester,
        ImportFlowState(step: ImportFlowStep.summary, summary: summary),
        'summary_$suffix',
        brightness: brightness,
      );
    });
  }
}
