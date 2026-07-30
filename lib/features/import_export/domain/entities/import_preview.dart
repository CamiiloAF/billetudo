import 'package:equatable/equatable.dart';

import 'import_preview_row.dart';
import 'import_row_issue.dart';

/// Result of `PreviewImport` (HU-06): every row resolved, plus the totals the
/// preview header shows ("N filas, M se importarán, K posibles duplicados...").
class ImportPreview extends Equatable {
  const ImportPreview({required this.rows});

  final List<ImportPreviewRow> rows;

  int get totalRows => rows.length;

  int get willImportCount =>
      rows.where((row) => row.status == ImportRowStatus.valid).length;

  int get duplicateCount => rows.where((row) => row.isDuplicate).length;

  int get invalidCount =>
      rows.where((row) => row.status == ImportRowStatus.invalid).length;

  Map<ImportRowIssue, int> get invalidCountsByReason {
    final counts = <ImportRowIssue, int>{};
    for (final row in rows) {
      final issue = row.invalidIssue;
      if (issue != null) {
        counts[issue] = (counts[issue] ?? 0) + 1;
      }
    }
    return counts;
  }

  @override
  List<Object?> get props => [rows];
}
