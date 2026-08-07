import 'package:billetudo/core/error/result.dart';
import 'package:billetudo/features/import_export/domain/entities/import_batch.dart';
import 'package:billetudo/features/import_export/domain/entities/import_commit_plan.dart';
import 'package:billetudo/features/import_export/domain/entities/import_destination.dart';
import 'package:billetudo/features/import_export/domain/entities/import_preview.dart';
import 'package:billetudo/features/import_export/domain/entities/import_preview_row.dart';
import 'package:billetudo/features/import_export/domain/entities/import_row_issue.dart';
import 'package:billetudo/features/import_export/domain/usecases/confirm_import.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'import_repository_mock.dart';

void main() {
  late MockImportRepository repository;
  late ConfirmImport confirmImport;

  final batch = ImportBatch(
    id: 'batch-1',
    fileName: 'movimientos.csv',
    importedAt: DateTime(2026, 1, 1),
    rowsImported: 1,
    rowsSkipped: 0,
    createdAt: DateTime(2026, 1, 1),
    updatedAt: 0,
  );

  const validRow = ImportPreviewRow(
    rowNumber: 1,
    status: ImportRowStatus.valid,
    includedByDefault: true,
    accountDestination: ExistingImportDestination('acc-1'),
  );

  const duplicateRow = ImportPreviewRow(
    rowNumber: 2,
    status: ImportRowStatus.duplicateExact,
    includedByDefault: false,
    accountDestination: ExistingImportDestination('acc-1'),
  );

  const invalidRow = ImportPreviewRow(
    rowNumber: 3,
    status: ImportRowStatus.invalid,
    includedByDefault: false,
    invalidIssue: ImportRowIssue.missingAmount,
  );

  setUpAll(registerImportRepositoryFallbacks);

  setUp(() {
    repository = MockImportRepository();
    confirmImport = ConfirmImport(repository);
    when(() => repository.commitImport(any()))
        .thenAnswer((_) async => Right(batch));
  });

  test('solo escribe las filas válidas incluidas por el usuario', () async {
    const preview = ImportPreview(rows: [validRow, duplicateRow, invalidRow]);

    await confirmImport(
      fileName: 'movimientos.csv',
      preview: preview,
      includedRowNumbers: {1},
    );

    final plan =
        verify(() => repository.commitImport(captureAny())).captured.single
            as ImportCommitPlan;
    expect(plan.rows, [validRow]);
  });

  test('una fila inválida nunca se escribe aunque el usuario la marque',
      () async {
    const preview = ImportPreview(rows: [invalidRow]);

    await confirmImport(
      fileName: 'movimientos.csv',
      preview: preview,
      includedRowNumbers: {3}, // intento de forzarla
    );

    final plan =
        verify(() => repository.commitImport(captureAny())).captured.single
            as ImportCommitPlan;
    expect(plan.rows, isEmpty);
    expect(plan.skippedErrorCount, 1);
  });

  test('un duplicado no marcado se cuenta como omitido por duplicado',
      () async {
    const preview = ImportPreview(rows: [duplicateRow]);

    final result = await confirmImport(
      fileName: 'movimientos.csv',
      preview: preview,
      includedRowNumbers: {},
    );

    final summary = result.getRight().toNullable()!;
    expect(summary.rowsSkippedDuplicate, 1);
    expect(summary.rowsImported, 0);
  });

  test('un duplicado que el usuario sí marca se importa', () async {
    const preview = ImportPreview(rows: [duplicateRow]);

    final result = await confirmImport(
      fileName: 'movimientos.csv',
      preview: preview,
      includedRowNumbers: {2},
    );

    final summary = result.getRight().toNullable()!;
    expect(summary.rowsImported, 1);
    expect(summary.rowsSkippedDuplicate, 0);
  });

  test('cuenta cuántas cuentas/categorías/etiquetas nuevas se crearon',
      () async {
    const rowWithNewDestinations = ImportPreviewRow(
      rowNumber: 1,
      status: ImportRowStatus.valid,
      includedByDefault: true,
      accountDestination: NewImportDestination('Cuenta Nueva'),
      categoryDestination: NewImportDestination('Categoría Nueva'),
      tags: ['viaje'],
      tagDestinations: [NewImportDestination('viaje')],
    );
    const preview = ImportPreview(rows: [rowWithNewDestinations]);

    final result = await confirmImport(
      fileName: 'movimientos.csv',
      preview: preview,
      includedRowNumbers: {1},
    );

    final summary = result.getRight().toNullable()!;
    expect(summary.accountsCreated, 1);
    expect(summary.categoriesCreated, 1);
    expect(summary.tagsCreated, 1);
  });
}
