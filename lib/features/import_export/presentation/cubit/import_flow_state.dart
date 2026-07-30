import 'package:equatable/equatable.dart';

import '../../../../core/error/result.dart';
import '../../domain/entities/column_mapping.dart';
import '../../domain/entities/csv_dialect.dart';
import '../../domain/entities/import_destination.dart';
import '../../domain/entities/import_preview.dart';
import '../../domain/entities/import_summary.dart';
import '../../domain/entities/mapping_template.dart';
import '../../domain/entities/parsed_csv_sample.dart';

/// HU-05/06/07: the import wizard's 4 numbered steps (chrome shows "2/4"-
/// "4/4" because "Seleccionar archivo" counts as an implicit step 1 —
/// `design-system/billetudo/pages/import-export.md`).
enum ImportFlowStep { fileSelect, mapping, destinations, preview, summary }

enum ImportFlowRunStatus {
  idle,
  working,

  /// The HU-05 write: `ConfirmImport` running inside one Drift transaction.
  /// Kept distinct from `working` (parsing/preview, which has no meaningful
  /// progress count or safe cancellation point) so only this phase shows a
  /// real `processed`/`total` and a functional "Cancelar".
  committing,
  error,
}

class ImportFlowState extends Equatable {
  const ImportFlowState({
    this.step = ImportFlowStep.fileSelect,
    this.runStatus = ImportFlowRunStatus.idle,
    this.filePath,
    this.fileName,
    this.sample,
    this.dialect = const CsvDialect(),
    this.mapping = const ColumnMapping(columns: {}),
    this.matchedTemplateName,
    this.templates = const [],
    this.accountOverrides = const {},
    this.categoryOverrides = const {},
    this.subcategoryOverrides = const {},
    this.tagOverrides = const {},
    this.preview,
    this.includedRowNumbers = const {},
    this.summary,
    this.failure,
    this.processed = 0,
    this.total = 0,
  });

  final ImportFlowStep step;
  final ImportFlowRunStatus runStatus;

  final String? filePath;
  final String? fileName;
  final ParsedCsvSample? sample;
  final CsvDialect dialect;
  final ColumnMapping mapping;

  /// Non-null when a saved template recognized this file's headers outright
  /// (HU-06).
  final String? matchedTemplateName;
  final List<MappingTemplate> templates;

  final Map<String, ImportDestination> accountOverrides;
  final Map<String, ImportDestination> categoryOverrides;
  final Map<String, ImportDestination> subcategoryOverrides;
  final Map<String, ImportDestination> tagOverrides;

  final ImportPreview? preview;

  /// The preview's checkbox state — starts as every row whose
  /// `includedByDefault` is `true` (HU-07: duplicates start unchecked).
  final Set<int> includedRowNumbers;

  final ImportSummary? summary;
  final Failure? failure;

  /// Rows committed so far / total rows to write — only meaningful while
  /// [runStatus] is `committing` (HU-05/HU-09).
  final int processed;
  final int total;

  bool get isWorking =>
      runStatus == ImportFlowRunStatus.working ||
      runStatus == ImportFlowRunStatus.committing;

  ImportFlowState copyWith({
    ImportFlowStep? step,
    ImportFlowRunStatus? runStatus,
    String? filePath,
    String? fileName,
    ParsedCsvSample? sample,
    CsvDialect? dialect,
    ColumnMapping? mapping,
    String? matchedTemplateName,
    bool clearMatchedTemplateName = false,
    List<MappingTemplate>? templates,
    Map<String, ImportDestination>? accountOverrides,
    Map<String, ImportDestination>? categoryOverrides,
    Map<String, ImportDestination>? subcategoryOverrides,
    Map<String, ImportDestination>? tagOverrides,
    ImportPreview? preview,
    Set<int>? includedRowNumbers,
    ImportSummary? summary,
    Failure? failure,
    int? processed,
    int? total,
  }) =>
      ImportFlowState(
        step: step ?? this.step,
        runStatus: runStatus ?? this.runStatus,
        filePath: filePath ?? this.filePath,
        fileName: fileName ?? this.fileName,
        sample: sample ?? this.sample,
        dialect: dialect ?? this.dialect,
        mapping: mapping ?? this.mapping,
        matchedTemplateName: clearMatchedTemplateName
            ? null
            : (matchedTemplateName ?? this.matchedTemplateName),
        templates: templates ?? this.templates,
        accountOverrides: accountOverrides ?? this.accountOverrides,
        categoryOverrides: categoryOverrides ?? this.categoryOverrides,
        subcategoryOverrides: subcategoryOverrides ?? this.subcategoryOverrides,
        tagOverrides: tagOverrides ?? this.tagOverrides,
        preview: preview ?? this.preview,
        includedRowNumbers: includedRowNumbers ?? this.includedRowNumbers,
        summary: summary ?? this.summary,
        failure: failure,
        processed: processed ?? this.processed,
        total: total ?? this.total,
      );

  @override
  List<Object?> get props => [
        step,
        runStatus,
        filePath,
        fileName,
        sample,
        dialect,
        mapping,
        matchedTemplateName,
        templates,
        accountOverrides,
        categoryOverrides,
        subcategoryOverrides,
        tagOverrides,
        preview,
        includedRowNumbers,
        summary,
        failure,
        processed,
        total,
      ];
}
