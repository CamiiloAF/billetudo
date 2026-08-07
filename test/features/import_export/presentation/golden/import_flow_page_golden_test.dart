import 'package:billetudo/features/import_export/domain/entities/column_mapping.dart';
import 'package:billetudo/features/import_export/domain/entities/csv_dialect.dart';
import 'package:billetudo/features/import_export/domain/entities/import_batch.dart';
import 'package:billetudo/features/import_export/domain/entities/import_destination.dart';
import 'package:billetudo/features/import_export/domain/entities/import_entry_type.dart';
import 'package:billetudo/features/import_export/domain/entities/import_mapping_mode.dart';
import 'package:billetudo/features/import_export/domain/entities/import_preview.dart';
import 'package:billetudo/features/import_export/domain/entities/import_preview_row.dart';
import 'package:billetudo/features/import_export/domain/entities/import_row_issue.dart';
import 'package:billetudo/features/import_export/domain/entities/import_summary.dart';
import 'package:billetudo/features/import_export/domain/entities/parsed_csv_sample.dart';
import 'package:billetudo/features/import_export/presentation/cubit/import_flow_cubit.dart';
import 'package:billetudo/features/import_export/presentation/cubit/import_flow_state.dart';
import 'package:billetudo/features/import_export/presentation/pages/import_flow_page.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../support/golden_helpers.dart';

class MockImportFlowCubit extends MockCubit<ImportFlowState> implements ImportFlowCubit {}

void main() {
  late MockImportFlowCubit cubit;

  final sample = const ParsedCsvSample(
    headers: ['FECHA_MOV', 'MONTO_COP', 'CUENTA', 'DESCRIPCION'],
    sampleRows: [
      ['2026-07-01', '19.99', 'Bancolombia', 'Mercado'],
    ],
    dialect: CsvDialect(),
    totalDataRowCount: 42,
  );

  final mapping = const ColumnMapping(
    columns: {
      ImportField.date: 0,
      ImportField.amount: 1,
      ImportField.account: 2,
      ImportField.note: 3,
    },
  );

  final previewForDestinations = ImportPreview(
    rows: [
      ImportPreviewRow(
        rowNumber: 2,
        status: ImportRowStatus.valid,
        includedByDefault: true,
        date: DateTime(2026, 7, 1),
        amountMinor: 1999,
        type: ImportEntryType.expense,
        accountDestination: const NewImportDestination('Mi Banco Nuevo'),
        categoryDestination: const NewImportDestination('Mercado'),
      ),
    ],
  );

  final previewForReview = ImportPreview(
    rows: [
      ImportPreviewRow(
        rowNumber: 2,
        status: ImportRowStatus.valid,
        includedByDefault: true,
        date: DateTime(2026, 7, 1),
        amountMinor: 1999,
        type: ImportEntryType.expense,
        note: 'Mercado de la semana',
      ),
      ImportPreviewRow(
        rowNumber: 3,
        status: ImportRowStatus.duplicateExact,
        includedByDefault: false,
        date: DateTime(2026, 7, 2),
        amountMinor: 5000,
        type: ImportEntryType.expense,
      ),
      ImportPreviewRow(
        rowNumber: 4,
        status: ImportRowStatus.invalid,
        includedByDefault: false,
        invalidIssue: ImportRowIssue.missingAmount,
      ),
    ],
  );

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
    Size size = goldenPhoneSize,
  }) async {
    when(() => cubit.state).thenReturn(state);
    await pumpGolden(
      tester,
      BlocProvider<ImportFlowCubit>.value(
        value: cubit,
        child: ImportFlowPage(onDone: () {}),
      ),
      brightness: brightness,
      settle: settle,
      size: size,
    );
    await expectLater(
      find.byType(ImportFlowPage),
      matchesGoldenFile('goldens/import_flow_page_$name.png'),
    );
  }

  for (final brightness in Brightness.values) {
    final suffix = brightness == Brightness.light ? 'light' : 'dark';

    testWidgets('mapping columns ($suffix)', (tester) async {
      await golden(
        tester,
        ImportFlowState(
          step: ImportFlowStep.mapping,
          sample: sample,
          mapping: mapping,
        ),
        'mapping_$suffix',
        brightness: brightness,
        size: tallGoldenPhoneSize(height: 1000),
      );
    });

    testWidgets('mapping columns, manual mode ($suffix)', (tester) async {
      await golden(
        tester,
        ImportFlowState(
          step: ImportFlowStep.mapping,
          sample: sample,
          mapping: mapping,
          mappingMode: ImportMappingMode.manual,
        ),
        'mapping_manual_$suffix',
        brightness: brightness,
        size: tallGoldenPhoneSize(height: 1400),
      );
    });

    testWidgets('mapping columns, template matched ($suffix)', (tester) async {
      await golden(
        tester,
        ImportFlowState(
          step: ImportFlowStep.mapping,
          sample: sample,
          mapping: mapping,
          matchedTemplateName: 'Mi banco',
        ),
        'mapping_template_matched_$suffix',
        brightness: brightness,
        size: tallGoldenPhoneSize(height: 1000),
      );
    });

    testWidgets('resolve destinations ($suffix)', (tester) async {
      await golden(
        tester,
        ImportFlowState(
          step: ImportFlowStep.destinations,
          preview: previewForDestinations,
        ),
        'destinations_$suffix',
        brightness: brightness,
      );
    });

    testWidgets(
      'resolve destinations, every row invalid — never "todo coincide" ($suffix)',
      (tester) async {
        await golden(
          tester,
          ImportFlowState(
            step: ImportFlowStep.destinations,
            preview: const ImportPreview(
              rows: [
                ImportPreviewRow(
                  rowNumber: 2,
                  status: ImportRowStatus.invalid,
                  includedByDefault: false,
                  invalidIssue: ImportRowIssue.invalidType,
                ),
                ImportPreviewRow(
                  rowNumber: 3,
                  status: ImportRowStatus.invalid,
                  includedByDefault: false,
                  invalidIssue: ImportRowIssue.invalidType,
                ),
              ],
            ),
          ),
          'destinations_all_invalid_$suffix',
          brightness: brightness,
        );
      },
    );

    testWidgets('final preview, severity hierarchy ($suffix)', (tester) async {
      await golden(
        tester,
        ImportFlowState(
          step: ImportFlowStep.preview,
          preview: previewForReview,
          includedRowNumbers: const {2},
        ),
        'preview_$suffix',
        brightness: brightness,
        size: tallGoldenPhoneSize(height: 1100),
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

    testWidgets('importing, blocking progress ($suffix)', (tester) async {
      await golden(
        tester,
        const ImportFlowState(
          runStatus: ImportFlowRunStatus.committing,
          processed: 25,
          total: 40,
        ),
        'progress_$suffix',
        brightness: brightness,
        settle: false,
      );
    });

    testWidgets('unreadable file error ($suffix)', (tester) async {
      await golden(
        tester,
        const ImportFlowState(runStatus: ImportFlowRunStatus.error),
        'error_unreadable_$suffix',
        brightness: brightness,
      );
    });
  }
}
