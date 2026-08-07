import 'dart:async';
import 'dart:io';

import 'package:billetudo/core/error/result.dart';
import 'package:billetudo/features/import_export/domain/entities/csv_vocabulary.dart';
import 'package:billetudo/features/import_export/domain/entities/export_scope.dart';
import 'package:billetudo/features/import_export/domain/usecases/export_accounts_categories_csv.dart';
import 'package:billetudo/features/import_export/domain/usecases/export_transactions_csv.dart';
import 'package:billetudo/features/import_export/domain/usecases/zip_export_files.dart';
import 'package:billetudo/features/import_export/presentation/cubit/export_cubit.dart';
import 'package:billetudo/features/import_export/presentation/cubit/export_state.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';

import 'fake_path_provider.dart';

class MockExportTransactionsCsv extends Mock implements ExportTransactionsCsv {}

class MockExportAccountsCategoriesCsv extends Mock
    implements ExportAccountsCategoriesCsv {}

class MockZipExportFiles extends Mock implements ZipExportFiles {}

void main() {
  late MockExportTransactionsCsv exportTransactionsCsv;
  late MockExportAccountsCategoriesCsv exportAccountsCategoriesCsv;
  late MockZipExportFiles zipExportFiles;
  late Directory tempDir;

  setUpAll(() {
    registerFallbackValue(const ExportScope());
    registerFallbackValue(CsvLanguage.es);
  });

  setUp(() {
    exportTransactionsCsv = MockExportTransactionsCsv();
    exportAccountsCategoriesCsv = MockExportAccountsCategoriesCsv();
    zipExportFiles = MockZipExportFiles();
    tempDir = Directory.systemTemp.createTempSync('billetudo_export_cubit_test');
    PathProviderPlatform.instance = FakePathProviderPlatform(tempDir.path);
  });

  tearDown(() {
    if (tempDir.existsSync()) {
      tempDir.deleteSync(recursive: true);
    }
  });

  ExportCubit build() =>
      ExportCubit(exportTransactionsCsv, exportAccountsCategoriesCsv, zipExportFiles);

  blocTest<ExportCubit, ExportState>(
    'start con transacciones disponibles preselecciona transacciones (HU-01)',
    build: build,
    act: (cubit) => cubit.start(hasAnyTransactions: true),
    expect: () => [
      isA<ExportState>()
          .having((s) => s.hasAnyTransactions, 'hasAnyTransactions', isTrue)
          .having(
            (s) => s.scope.includeTransactions,
            'includeTransactions',
            isTrue,
          ),
    ],
  );

  blocTest<ExportCubit, ExportState>(
    'start sin transacciones no las preselecciona (hub vacío)',
    build: build,
    act: (cubit) => cubit.start(hasAnyTransactions: false),
    expect: () => [
      isA<ExportState>().having(
        (s) => s.scope.includeTransactions,
        'includeTransactions',
        isFalse,
      ),
    ],
  );

  blocTest<ExportCubit, ExportState>(
    'elegir cuentas y categorías activa bundlesIntoZip (HU-02)',
    build: build,
    act: (cubit) {
      cubit.start(hasAnyTransactions: false);
      cubit.toggleIncludeAccounts(value: true);
      cubit.toggleIncludeCategories(value: true);
    },
    verify: (cubit) => expect(cubit.state.scope.bundlesIntoZip, isTrue),
  );

  blocTest<ExportCubit, ExportState>(
    'todo el histórico se puede activar y desactivar',
    build: build,
    act: (cubit) {
      cubit.start(hasAnyTransactions: true);
      cubit.toggleAllHistory(value: true);
    },
    verify: (cubit) => expect(cubit.state.scope.allHistory, isTrue),
  );

  blocTest<ExportCubit, ExportState>(
    'confirm reporta progreso real emitido por el caso de uso (HU-01/HU-09)',
    setUp: () {
      when(
        () => exportTransactionsCsv(
          outputPath: any(named: 'outputPath'),
          scope: any(named: 'scope'),
          language: any(named: 'language'),
          onProgress: any(named: 'onProgress'),
          cancellationToken: any(named: 'cancellationToken'),
        ),
      ).thenAnswer((invocation) async {
        final onProgress = invocation.namedArguments[#onProgress] as void
            Function(int, int?)?;
        onProgress?.call(0, 3);
        onProgress?.call(1, 3);
        onProgress?.call(3, 3);
        return const Right(3);
      });
    },
    build: build,
    act: (cubit) {
      cubit.start(hasAnyTransactions: true);
      unawaited(cubit.confirm(language: 'es'));
    },
    wait: const Duration(milliseconds: 50),
    verify: (cubit) {
      expect(cubit.state.processed, 3);
      expect(cubit.state.total, 3);
      expect(cubit.state.runStatus, ExportRunStatus.done);
    },
  );

  blocTest<ExportCubit, ExportState>(
    'cancel detiene el export: estado queda "cancelled", no "error" (HU-01)',
    setUp: () {
      when(
        () => exportTransactionsCsv(
          outputPath: any(named: 'outputPath'),
          scope: any(named: 'scope'),
          language: any(named: 'language'),
          onProgress: any(named: 'onProgress'),
          cancellationToken: any(named: 'cancellationToken'),
        ),
      ).thenAnswer(
        (_) async => const Left(
          IoFailure('export cancelled', reason: IoFailureReason.cancelled),
        ),
      );
    },
    build: build,
    act: (cubit) async {
      cubit.start(hasAnyTransactions: true);
      await cubit.confirm(language: 'es');
    },
    verify: (cubit) {
      expect(cubit.state.runStatus, ExportRunStatus.cancelled);
      expect(cubit.state.failure, isNull);
    },
  );
}
