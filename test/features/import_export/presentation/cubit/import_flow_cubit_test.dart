import 'package:billetudo/core/error/result.dart';
import 'package:billetudo/features/import_export/domain/entities/import_batch.dart';
import 'package:billetudo/features/import_export/domain/entities/import_destination.dart';
import 'package:billetudo/features/import_export/domain/entities/import_preview.dart';
import 'package:billetudo/features/import_export/domain/entities/import_preview_row.dart';
import 'package:billetudo/features/import_export/domain/entities/import_summary.dart';
import 'package:billetudo/features/import_export/domain/usecases/autodetect_column_mapping.dart';
import 'package:billetudo/features/import_export/domain/usecases/confirm_import.dart';
import 'package:billetudo/features/import_export/domain/usecases/get_existing_accounts_for_import.dart';
import 'package:billetudo/features/import_export/domain/usecases/get_existing_root_categories_for_import.dart';
import 'package:billetudo/features/import_export/domain/usecases/get_existing_subcategories_for_import.dart';
import 'package:billetudo/features/import_export/domain/usecases/get_existing_tags_for_import.dart';
import 'package:billetudo/features/import_export/domain/usecases/get_mapping_templates.dart';
import 'package:billetudo/features/import_export/domain/usecases/parse_csv_headers.dart';
import 'package:billetudo/features/import_export/domain/usecases/preview_import.dart';
import 'package:billetudo/features/import_export/domain/usecases/save_mapping_template.dart';
import 'package:billetudo/features/import_export/presentation/cubit/import_flow_cubit.dart';
import 'package:billetudo/features/import_export/presentation/cubit/import_flow_state.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockParseCsvHeaders extends Mock implements ParseCsvHeaders {}

class MockAutodetectColumnMapping extends Mock implements AutodetectColumnMapping {}

class MockGetMappingTemplates extends Mock implements GetMappingTemplates {}

class MockPreviewImport extends Mock implements PreviewImport {}

class MockConfirmImport extends Mock implements ConfirmImport {}

class MockSaveMappingTemplate extends Mock implements SaveMappingTemplate {}

class MockGetExistingAccountsForImport extends Mock
    implements GetExistingAccountsForImport {}

class MockGetExistingRootCategoriesForImport extends Mock
    implements GetExistingRootCategoriesForImport {}

class MockGetExistingSubcategoriesForImport extends Mock
    implements GetExistingSubcategoriesForImport {}

class MockGetExistingTagsForImport extends Mock implements GetExistingTagsForImport {}

void main() {
  late MockParseCsvHeaders parseCsvHeaders;
  late MockAutodetectColumnMapping autodetectColumnMapping;
  late MockGetMappingTemplates getMappingTemplates;
  late MockPreviewImport previewImport;
  late MockConfirmImport confirmImport;
  late MockSaveMappingTemplate saveMappingTemplate;
  late MockGetExistingAccountsForImport getExistingAccounts;
  late MockGetExistingRootCategoriesForImport getExistingRootCategories;
  late MockGetExistingSubcategoriesForImport getExistingSubcategories;
  late MockGetExistingTagsForImport getExistingTags;

  const validRow = ImportPreviewRow(
    rowNumber: 1,
    status: ImportRowStatus.valid,
    includedByDefault: true,
    accountDestination: ExistingImportDestination('acc-1'),
  );
  const preview = ImportPreview(rows: [validRow]);

  final batch = ImportBatch(
    id: 'batch-1',
    fileName: 'movimientos.csv',
    importedAt: DateTime(2026, 1, 1),
    rowsImported: 1,
    rowsSkipped: 0,
    createdAt: DateTime(2026, 1, 1),
    updatedAt: 0,
  );
  late ImportSummary summary;

  setUpAll(() {
    registerFallbackValue(preview);
    registerFallbackValue(<int>{});
  });

  setUp(() {
    parseCsvHeaders = MockParseCsvHeaders();
    autodetectColumnMapping = MockAutodetectColumnMapping();
    getMappingTemplates = MockGetMappingTemplates();
    previewImport = MockPreviewImport();
    confirmImport = MockConfirmImport();
    saveMappingTemplate = MockSaveMappingTemplate();
    getExistingAccounts = MockGetExistingAccountsForImport();
    getExistingRootCategories = MockGetExistingRootCategoriesForImport();
    getExistingSubcategories = MockGetExistingSubcategoriesForImport();
    getExistingTags = MockGetExistingTagsForImport();
    summary = ImportSummary(
      batch: batch,
      rowsImported: 1,
      rowsSkippedDuplicate: 0,
      rowsSkippedError: 0,
      accountsCreated: 0,
      categoriesCreated: 0,
      tagsCreated: 0,
    );
  });

  ImportFlowCubit build() => ImportFlowCubit(
        parseCsvHeaders,
        autodetectColumnMapping,
        getMappingTemplates,
        previewImport,
        confirmImport,
        saveMappingTemplate,
        getExistingAccounts,
        getExistingRootCategories,
        getExistingSubcategories,
        getExistingTags,
      );

  group('confirm — HU-05/HU-09', () {
    blocTest<ImportFlowCubit, ImportFlowState>(
      'reporta progreso real (filas escritas / total) mientras confirma',
      setUp: () {
        when(
          () => confirmImport(
            fileName: any(named: 'fileName'),
            preview: any(named: 'preview'),
            includedRowNumbers: any(named: 'includedRowNumbers'),
            templateName: any(named: 'templateName'),
            onProgress: any(named: 'onProgress'),
            cancellationToken: any(named: 'cancellationToken'),
          ),
        ).thenAnswer((invocation) async {
          final onProgress =
              invocation.namedArguments[#onProgress] as void Function(int, int?)?;
          onProgress?.call(0, 1);
          onProgress?.call(1, 1);
          return Right(summary);
        });
      },
      build: build,
      seed: () => const ImportFlowState(
        step: ImportFlowStep.preview,
        fileName: 'movimientos.csv',
        preview: preview,
        includedRowNumbers: {1},
      ),
      act: (cubit) => cubit.confirm(),
      verify: (cubit) {
        expect(cubit.state.processed, 1);
        expect(cubit.state.total, 1);
        expect(cubit.state.step, ImportFlowStep.summary);
        expect(cubit.state.runStatus, ImportFlowRunStatus.idle);
      },
    );

    blocTest<ImportFlowCubit, ImportFlowState>(
      'cancel vuelve a la vista previa (rollback: HU-05 "no deja filas a medias")',
      setUp: () {
        when(
          () => confirmImport(
            fileName: any(named: 'fileName'),
            preview: any(named: 'preview'),
            includedRowNumbers: any(named: 'includedRowNumbers'),
            templateName: any(named: 'templateName'),
            onProgress: any(named: 'onProgress'),
            cancellationToken: any(named: 'cancellationToken'),
          ),
        ).thenAnswer(
          (_) async => const Left(
            IoFailure('import cancelled', reason: IoFailureReason.cancelled),
          ),
        );
      },
      build: build,
      seed: () => const ImportFlowState(
        step: ImportFlowStep.preview,
        fileName: 'movimientos.csv',
        preview: preview,
        includedRowNumbers: {1},
      ),
      act: (cubit) => cubit.confirm(),
      verify: (cubit) {
        expect(cubit.state.step, ImportFlowStep.preview);
        expect(cubit.state.runStatus, ImportFlowRunStatus.idle);
        expect(cubit.state.failure, isNull);
      },
    );

    blocTest<ImportFlowCubit, ImportFlowState>(
      'muestra estado "committing" (con progreso real) mientras escribe, no "working" genérico',
      setUp: () {
        when(
          () => confirmImport(
            fileName: any(named: 'fileName'),
            preview: any(named: 'preview'),
            includedRowNumbers: any(named: 'includedRowNumbers'),
            templateName: any(named: 'templateName'),
            onProgress: any(named: 'onProgress'),
            cancellationToken: any(named: 'cancellationToken'),
          ),
        ).thenAnswer((_) async => Right(summary));
      },
      build: build,
      seed: () => const ImportFlowState(
        step: ImportFlowStep.preview,
        fileName: 'movimientos.csv',
        preview: preview,
        includedRowNumbers: {1},
      ),
      act: (cubit) => cubit.confirm(),
      expect: () => [
        isA<ImportFlowState>()
            .having((s) => s.runStatus, 'runStatus', ImportFlowRunStatus.working),
        isA<ImportFlowState>()
            .having((s) => s.runStatus, 'runStatus', ImportFlowRunStatus.committing),
        isA<ImportFlowState>()
            .having((s) => s.runStatus, 'runStatus', ImportFlowRunStatus.idle)
            .having((s) => s.step, 'step', ImportFlowStep.summary),
      ],
    );
  });
}
