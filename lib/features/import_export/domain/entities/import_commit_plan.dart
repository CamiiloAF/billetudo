import 'package:equatable/equatable.dart';

import 'import_preview_row.dart';

/// What `ConfirmImport` hands to `ImportRepository.commitImport` (HU-05/06):
/// only the rows the user kept checked, already resolved. Everything else
/// (creating the batch, resolving `NewImportDestination` names to fresh
/// accounts/categories/tags, stamping `importBatchId`, `source = imported`)
/// happens in `data/`, in one transaction.
class ImportCommitPlan extends Equatable {
  const ImportCommitPlan({
    required this.fileName,
    required this.rows,
    required this.skippedDuplicateCount,
    required this.skippedErrorCount,
    this.templateName,
  });

  final String fileName;
  final String? templateName;

  /// Only rows with [ImportPreviewRow.status] `valid` or a duplicate the
  /// user explicitly kept checked. Never an `invalid` row — `ConfirmImport`
  /// filters those out before this plan exists.
  final List<ImportPreviewRow> rows;

  /// For the batch's own `rowsSkipped` count and the closing summary — these
  /// rows are not in [rows], so the count is passed alongside instead of
  /// re-derived from a list `data/` never sees.
  final int skippedDuplicateCount;
  final int skippedErrorCount;

  @override
  List<Object?> get props => [
        fileName,
        templateName,
        rows,
        skippedDuplicateCount,
        skippedErrorCount,
      ];
}
