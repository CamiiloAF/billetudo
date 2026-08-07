import 'package:injectable/injectable.dart';

import '../../../../core/error/result.dart';
import '../entities/cancellation_token.dart';
import '../entities/import_commit_plan.dart';
import '../entities/import_destination.dart';
import '../entities/import_preview.dart';
import '../entities/import_preview_row.dart';
import '../entities/import_summary.dart';
import '../entities/progress_callback.dart';
import '../repositories/import_repository.dart';

/// HU-05/06: writes the rows the user kept checked — "nada se escribe hasta
/// que el usuario confirma la vista previa".
///
/// `includedRowNumbers` is the checkbox state from the preview screen
/// (HU-07: duplicates start unchecked, so a duplicate only lands here if the
/// user explicitly ticked it). Invalid rows are dropped regardless of
/// whatever `includedRowNumbers` says — they were never selectable.
@injectable
class ConfirmImport {
  const ConfirmImport(this._repository);

  final ImportRepository _repository;

  FutureResult<ImportSummary> call({
    required String fileName,
    required ImportPreview preview,
    required Set<int> includedRowNumbers,
    String? templateName,
    ProgressCallback? onProgress,
    CancellationToken? cancellationToken,
  }) async {
    final rowsToWrite = <ImportPreviewRow>[];
    var skippedDuplicate = 0;
    var skippedError = 0;

    for (final row in preview.rows) {
      if (row.status == ImportRowStatus.invalid) {
        skippedError++;
        continue;
      }
      if (includedRowNumbers.contains(row.rowNumber)) {
        rowsToWrite.add(row);
      } else if (row.isDuplicate) {
        skippedDuplicate++;
      }
      // A `valid` row the user unchecked is simply not written and not
      // counted anywhere — HU-06 only tracks "omitida por duplicado" and
      // "omitida por error", there is no third bucket for that case.
    }

    final plan = ImportCommitPlan(
      fileName: fileName,
      templateName: templateName,
      rows: rowsToWrite,
      skippedDuplicateCount: skippedDuplicate,
      skippedErrorCount: skippedError,
    );

    final result = await _repository.commitImport(
      plan,
      onProgress: onProgress,
      cancellationToken: cancellationToken,
    );
    return result.fold(Left.new, (batch) {
      final accountsCreated = <String>{};
      final categoriesCreated = <String>{};
      final tagsCreated = <String>{};
      for (final row in rowsToWrite) {
        _collectNewName(row.accountDestination, accountsCreated);
        _collectNewName(row.transferAccountDestination, accountsCreated);
        _collectNewName(row.categoryDestination, categoriesCreated);
        _collectNewName(row.subcategoryDestination, categoriesCreated);
        for (final tagDestination in row.tagDestinations) {
          _collectNewName(tagDestination, tagsCreated);
        }
      }
      return Right(
        ImportSummary(
          batch: batch,
          rowsImported: rowsToWrite.length,
          rowsSkippedDuplicate: skippedDuplicate,
          rowsSkippedError: skippedError,
          accountsCreated: accountsCreated.length,
          categoriesCreated: categoriesCreated.length,
          tagsCreated: tagsCreated.length,
        ),
      );
    });
  }

  void _collectNewName(ImportDestination? destination, Set<String> into) {
    if (destination is NewImportDestination) {
      into.add(destination.name);
    }
  }
}
