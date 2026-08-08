import 'package:clock/clock.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/error/result.dart';
import '../../domain/entities/cancellation_token.dart';
import '../../domain/entities/column_mapping.dart';
import '../../domain/entities/csv_dialect.dart';
import '../../domain/entities/import_destination.dart';
import '../../domain/entities/import_mapping_mode.dart';
import '../../domain/entities/import_preview.dart';
import '../../domain/entities/import_summary.dart';
import '../../domain/entities/mapping_template.dart';
import '../../domain/entities/named_entity.dart';
import '../../domain/entities/parsed_csv_sample.dart';
import '../../domain/usecases/autodetect_column_mapping.dart';
import '../../domain/usecases/confirm_import.dart';
import '../../domain/usecases/get_existing_accounts_for_import.dart';
import '../../domain/usecases/get_existing_root_categories_for_import.dart';
import '../../domain/usecases/get_existing_subcategories_for_import.dart';
import '../../domain/usecases/get_existing_tags_for_import.dart';
import '../../domain/usecases/get_mapping_templates.dart';
import '../../domain/usecases/parse_csv_headers.dart';
import '../../domain/usecases/preview_import.dart';
import '../../domain/usecases/save_mapping_template.dart';
import 'import_flow_state.dart';

/// Drives the whole import wizard (HU-05/06/07): pick a file, map its
/// columns, resolve unmatched destinations, review the final preview and
/// confirm.
@injectable
class ImportFlowCubit extends Cubit<ImportFlowState> {
  ImportFlowCubit(
    this._parseCsvHeaders,
    this._autodetectColumnMapping,
    this._getMappingTemplates,
    this._previewImport,
    this._confirmImport,
    this._saveMappingTemplate,
    this._getExistingAccounts,
    this._getExistingRootCategories,
    this._getExistingSubcategories,
    this._getExistingTags,
  ) : super(const ImportFlowState());

  final ParseCsvHeaders _parseCsvHeaders;
  final AutodetectColumnMapping _autodetectColumnMapping;
  final GetMappingTemplates _getMappingTemplates;
  final PreviewImport _previewImport;
  final ConfirmImport _confirmImport;
  final SaveMappingTemplate _saveMappingTemplate;
  final GetExistingAccountsForImport _getExistingAccounts;
  final GetExistingRootCategoriesForImport _getExistingRootCategories;
  final GetExistingSubcategoriesForImport _getExistingSubcategories;
  final GetExistingTagsForImport _getExistingTags;

  CancellationToken? _cancellationToken;

  /// For the "mapear a existente" picker (HU-06). Each returns an empty list
  /// on failure rather than surfacing a whole-flow error for what is, at
  /// that point, a secondary lookup — the destination simply stays
  /// resolvable only as "crear nueva".
  Future<List<NamedEntity>> loadExistingAccounts() =>
      _getExistingAccounts().then((r) => r.fold((_) => const [], (v) => v));

  Future<List<NamedEntity>> loadExistingRootCategories(
          {required bool isExpense}) =>
      _getExistingRootCategories(isExpense: isExpense)
          .then((r) => r.fold((_) => const [], (v) => v));

  Future<List<NamedEntity>> loadExistingSubcategories(String parentId) =>
      _getExistingSubcategories(parentId)
          .then((r) => r.fold((_) => const [], (v) => v));

  Future<List<NamedEntity>> loadExistingTags() =>
      _getExistingTags().then((r) => r.fold((_) => const [], (v) => v));

  void reset() => emit(const ImportFlowState());

  /// Opens the native file picker (HU-05 entry, `W2hiZK`) and starts parsing
  /// on success. No-op if the user backs out.
  Future<void> pickFile() async {
    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['csv'],
    );
    final path = result?.files.single.path;
    if (path == null) {
      return;
    }
    await _loadFile(path, result!.files.single.name);
  }

  Future<void> _loadFile(String path, String name) async {
    emit(
      state.copyWith(
        runStatus: ImportFlowRunStatus.working,
        filePath: path,
        fileName: name,
      ),
    );

    final templatesResult = await _getMappingTemplates();
    final templates =
        templatesResult.fold((_) => <MappingTemplate>[], (t) => t);

    final sampleResult = await _parseCsvHeaders(path);
    if (isClosed) {
      return;
    }
    if (sampleResult case Left(value: final failure)) {
      emit(
        state.copyWith(runStatus: ImportFlowRunStatus.error, failure: failure),
      );
      return;
    }
    final sample = (sampleResult as Right<Failure, ParsedCsvSample>).value;

    final autodetected = _autodetectColumnMapping(
      headers: sample.headers,
      detectedDialect: sample.dialect,
      savedTemplates: templates,
      sampleRows: sample.sampleRows,
    );

    emit(
      state.copyWith(
        runStatus: ImportFlowRunStatus.idle,
        sample: sample,
        templates: templates,
        dialect: autodetected.dialect,
        mapping: autodetected.mapping,
        mappingMode: ImportMappingMode.automatic,
        matchedTemplateName: autodetected.matchedTemplateName,
        clearMatchedTemplateName: autodetected.matchedTemplateName == null,
        step: ImportFlowStep.mapping,
      ),
    );
  }

  // -- Step 2: column mapping --

  /// Maps CSV column [headerIndex] to [field] (`null` clears it). A field can
  /// only point at one column at a time, so re-assigning it here drops it
  /// from wherever it was mapped before.
  void setFieldForColumn(int headerIndex, ImportField? field) {
    final columns = Map<ImportField, int>.from(state.mapping.columns)
      ..removeWhere((_, index) => index == headerIndex);
    if (field != null) {
      columns[field] = headerIndex;
    }
    emit(state.copyWith(mapping: state.mapping.copyWith(columns: columns)));
  }

  void setTypeValues(TypeColumnValues values) =>
      emit(state.copyWith(mapping: state.mapping.copyWith(typeValues: values)));

  void setDialect(CsvDialect dialect) => emit(state.copyWith(dialect: dialect));

  /// Switches the mapping step between its one-tap "Automático" summary and
  /// the fully manual column-by-column view.
  void setMappingMode(ImportMappingMode mode) =>
      emit(state.copyWith(mappingMode: mode));

  /// Applies the date-format sheet's choice (order + separator) to the
  /// current dialect, leaving the decimal convention untouched.
  void applyDateFormat(DateComponentOrder order, DateSeparatorChar separator) =>
      emit(
        state.copyWith(
          dialect: state.dialect
              .copyWith(dateOrder: order, dateSeparator: separator),
        ),
      );

  /// Applies the decimal-convention sheet's choice, leaving the date format
  /// untouched.
  void applyDecimalConvention(DecimalConvention convention) => emit(
        state.copyWith(
            dialect: state.dialect.copyWith(decimalConvention: convention)),
      );

  /// Applies the type-values sheet's "columna de tipo" choice: maps
  /// [columnIndex] to [ImportField.type] (dropping it from wherever it was
  /// mapped before, same rule as [setFieldForColumn]) and records [values] as
  /// the literals that mean income/expense/transfer in that column.
  void applyTypeColumn(int columnIndex, TypeColumnValues values) {
    final columns = Map<ImportField, int>.from(state.mapping.columns)
      ..removeWhere((_, index) => index == columnIndex)
      ..[ImportField.type] = columnIndex;
    emit(
      state.copyWith(
        mapping: ColumnMapping(columns: columns, typeValues: values),
      ),
    );
  }

  /// Applies the type-values sheet's "signo del monto" choice: unmaps
  /// [ImportField.type] entirely and clears [ColumnMapping.typeValues], so
  /// `PreviewImport` falls back to reading the amount's sign as the
  /// income/expense direction.
  void applyAmountSignMode() {
    final columns = Map<ImportField, int>.from(state.mapping.columns)
      ..remove(ImportField.type);
    emit(state.copyWith(mapping: ColumnMapping(columns: columns)));
  }

  /// Advances to "Resolver destinos" by running the first pass of
  /// `PreviewImport` with no overrides — every unmatched name starts as
  /// `NewImportDestination` (HU-06 default "crear nueva").
  Future<void> confirmMapping() async {
    if (!state.mapping.isComplete) {
      return;
    }
    await _runPreview(goToStep: ImportFlowStep.destinations);
  }

  // -- Step 3: destination resolution --

  void setAccountOverride(String key, ImportDestination destination) {
    final overrides =
        Map<String, ImportDestination>.from(state.accountOverrides)
          ..[key] = destination;
    emit(state.copyWith(accountOverrides: overrides));
  }

  void setCategoryOverride(String key, ImportDestination destination) {
    final overrides =
        Map<String, ImportDestination>.from(state.categoryOverrides)
          ..[key] = destination;
    emit(state.copyWith(categoryOverrides: overrides));
  }

  void setSubcategoryOverride(String key, ImportDestination destination) {
    final overrides =
        Map<String, ImportDestination>.from(state.subcategoryOverrides)
          ..[key] = destination;
    emit(state.copyWith(subcategoryOverrides: overrides));
  }

  void setTagOverride(String key, ImportDestination destination) {
    final overrides = Map<String, ImportDestination>.from(state.tagOverrides)
      ..[key] = destination;
    emit(state.copyWith(tagOverrides: overrides));
  }

  /// Re-runs `PreviewImport` with the current overrides applied, then moves
  /// to the final preview (HU-06).
  Future<void> confirmDestinations() async {
    await _runPreview(goToStep: ImportFlowStep.preview);
  }

  Future<void> _runPreview({required ImportFlowStep goToStep}) async {
    final filePath = state.filePath;
    if (filePath == null) {
      return;
    }
    emit(state.copyWith(runStatus: ImportFlowRunStatus.working));
    final result = await _previewImport(
      filePath: filePath,
      mapping: state.mapping,
      dialect: state.dialect,
      accountOverrides: state.accountOverrides,
      categoryOverrides: state.categoryOverrides,
      subcategoryOverrides: state.subcategoryOverrides,
      tagOverrides: state.tagOverrides,
    );
    if (isClosed) {
      return;
    }
    if (result case Left(value: final failure)) {
      emit(state.copyWith(
          runStatus: ImportFlowRunStatus.error, failure: failure));
      return;
    }
    final preview = (result as Right<Failure, ImportPreview>).value;
    emit(
      state.copyWith(
        runStatus: ImportFlowRunStatus.idle,
        preview: preview,
        includedRowNumbers: {
          for (final row in preview.rows)
            if (row.includedByDefault) row.rowNumber,
        },
        step: goToStep,
      ),
    );
  }

  // -- Step 4: final preview (HU-06/HU-07) --

  void toggleRow(int rowNumber, {required bool included}) {
    final updated = Set<int>.from(state.includedRowNumbers);
    if (included) {
      updated.add(rowNumber);
    } else {
      updated.remove(rowNumber);
    }
    emit(state.copyWith(includedRowNumbers: updated));
  }

  void includeAllDuplicates() {
    final preview = state.preview;
    if (preview == null) {
      return;
    }
    final updated = Set<int>.from(state.includedRowNumbers);
    for (final row in preview.rows) {
      if (row.isDuplicate) {
        updated.add(row.rowNumber);
      }
    }
    emit(state.copyWith(includedRowNumbers: updated));
  }

  void omitAllDuplicates() {
    final preview = state.preview;
    if (preview == null) {
      return;
    }
    final updated = Set<int>.from(state.includedRowNumbers);
    for (final row in preview.rows) {
      if (row.isDuplicate) {
        updated.remove(row.rowNumber);
      }
    }
    emit(state.copyWith(includedRowNumbers: updated));
  }

  /// Writes the confirmed rows (HU-05/06), optionally saving the mapping as
  /// a reusable template (HU-06), then moves to the summary step.
  Future<void> confirm({String? saveTemplateAs}) async {
    final preview = state.preview;
    final fileName = state.fileName;
    if (preview == null || fileName == null) {
      return;
    }
    emit(state.copyWith(runStatus: ImportFlowRunStatus.working));

    if (saveTemplateAs != null && saveTemplateAs.trim().isNotEmpty) {
      await _saveMappingTemplate(
        MappingTemplate(
          name: saveTemplateAs,
          headerNames: state.sample?.headers ?? const [],
          dialect: state.dialect,
          mapping: state.mapping,
          savedAt: clock.now(),
        ),
      );
    }
    if (isClosed) {
      return;
    }

    final token = CancellationToken();
    _cancellationToken = token;
    emit(
      state.copyWith(
        runStatus: ImportFlowRunStatus.committing,
        processed: 0,
        total: state.includedRowNumbers.length,
      ),
    );

    final result = await _confirmImport(
      fileName: fileName,
      preview: preview,
      includedRowNumbers: state.includedRowNumbers,
      templateName: saveTemplateAs,
      onProgress: (processed, total) {
        if (!isClosed) {
          emit(state.copyWith(processed: processed, total: total ?? 0));
        }
      },
      cancellationToken: token,
    );
    _cancellationToken = null;
    if (isClosed) {
      return;
    }
    if (result case Left(value: final failure)) {
      final cancelled =
          failure is IoFailure && failure.reason == IoFailureReason.cancelled;
      emit(
        // HU-05/HU-09: cancelling rolls back the single write transaction —
        // returning to the preview step (not an error screen) lets the user
        // just try again, same as `RestoreCubit`.
        cancelled
            ? state.copyWith(
                runStatus: ImportFlowRunStatus.idle,
                step: ImportFlowStep.preview,
              )
            : state.copyWith(
                runStatus: ImportFlowRunStatus.error, failure: failure),
      );
      return;
    }
    final summary = (result as Right<Failure, ImportSummary>).value;
    emit(
      state.copyWith(
        runStatus: ImportFlowRunStatus.idle,
        summary: summary,
        step: ImportFlowStep.summary,
      ),
    );
  }

  /// Stops the running commit at the next row boundary; because the whole
  /// write is one Drift transaction, this rolls it back (HU-05: "cancelar no
  /// deja filas a medias").
  void cancel() => _cancellationToken?.cancel();

  void goToStep(ImportFlowStep step) => emit(state.copyWith(step: step));
}
