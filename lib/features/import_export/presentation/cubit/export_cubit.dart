import 'package:clock/clock.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../core/error/result.dart';
import '../../domain/entities/cancellation_token.dart';
import '../../domain/entities/csv_vocabulary.dart';
import '../../domain/entities/export_scope.dart';
import '../../domain/entities/import_entry_type.dart';
import '../../domain/usecases/export_accounts_categories_csv.dart';
import '../../domain/usecases/export_transactions_csv.dart';
import '../../domain/usecases/zip_export_files.dart';
import 'export_state.dart';

/// Drives HU-01/HU-02: what to export, optionally filtered, delivered by the
/// system share sheet.
@injectable
class ExportCubit extends Cubit<ExportState> {
  ExportCubit(
    this._exportTransactionsCsv,
    this._exportAccountsCategoriesCsv,
    this._zipExportFiles,
  ) : super(const ExportState());

  final ExportTransactionsCsv _exportTransactionsCsv;
  final ExportAccountsCategoriesCsv _exportAccountsCategoriesCsv;
  final ZipExportFiles _zipExportFiles;

  CancellationToken? _cancellationToken;

  void start({required bool hasAnyTransactions}) {
    emit(
      ExportState(
        hasAnyTransactions: hasAnyTransactions,
        scope: ExportScope(includeTransactions: hasAnyTransactions),
      ),
    );
  }

  void toggleIncludeTransactions({required bool value}) =>
      emit(state.copyWith(scope: _copyScope(includeTransactions: value)));

  void toggleIncludeAccounts({required bool value}) =>
      emit(state.copyWith(scope: _copyScope(includeAccounts: value)));

  void toggleIncludeCategories({required bool value}) =>
      emit(state.copyWith(scope: _copyScope(includeCategories: value)));

  void toggleAllHistory({required bool value}) =>
      emit(state.copyWith(scope: _copyScope(allHistory: value)));

  void updateDateRange(DateTime start, DateTime end) => emit(
        state.copyWith(
          scope: _copyScope(
            transactionFilter: state.scope.transactionFilter
                .copyWith(startDate: start, endDate: end),
          ),
        ),
      );

  void setSearchText(String value) => emit(
        state.copyWith(
          scope: _copyScope(
            transactionFilter:
                state.scope.transactionFilter.copyWith(searchText: value),
          ),
        ),
      );

  void setAccountFilter(Set<String> accountIds) => emit(
        state.copyWith(
          scope: _copyScope(
            transactionFilter:
                state.scope.transactionFilter.copyWith(accountIds: accountIds),
          ),
        ),
      );

  void setCategoryFilter(Set<String> categoryIds) => emit(
        state.copyWith(
          scope: _copyScope(
            transactionFilter: state.scope.transactionFilter
                .copyWith(categoryIds: categoryIds),
          ),
        ),
      );

  void setTypeFilter(Set<ImportEntryType> types) => emit(
        state.copyWith(
          scope: _copyScope(
            transactionFilter:
                state.scope.transactionFilter.copyWith(types: types),
          ),
        ),
      );

  void setTagFilter(Set<String> tagIds) => emit(
        state.copyWith(
          scope: _copyScope(
            transactionFilter:
                state.scope.transactionFilter.copyWith(tagIds: tagIds),
          ),
        ),
      );

  ExportScope _copyScope({
    bool? includeTransactions,
    bool? includeAccounts,
    bool? includeCategories,
    bool? allHistory,
    TransactionExportFilter? transactionFilter,
  }) =>
      ExportScope(
        includeTransactions:
            includeTransactions ?? state.scope.includeTransactions,
        includeAccounts: includeAccounts ?? state.scope.includeAccounts,
        includeCategories: includeCategories ?? state.scope.includeCategories,
        allHistory: allHistory ?? state.scope.allHistory,
        transactionFilter: transactionFilter ?? state.scope.transactionFilter,
      );

  /// Writes every selected kind, zipping when more than one was chosen
  /// (HU-02), and leaves [ExportState.resultFilePath] set for the page to
  /// hand to the share sheet.
  ///
  /// Progress is a running count across every file this call writes: each
  /// phase (transactions, then accounts/categories) reports its own
  /// processed/total, offset by what earlier phases already wrote, so the
  /// bar in [ExportState] never goes backwards. [cancel] stops the write at
  /// the next row boundary and deletes the partial file (HU-01).
  Future<void> confirm({required String language}) async {
    final scope = state.scope;
    if (!scope.selectionCount) {
      return;
    }
    final token = CancellationToken();
    _cancellationToken = token;
    emit(
      state.copyWith(
        runStatus: ExportRunStatus.running,
        processed: 0,
        total: 0,
        clearResult: true,
      ),
    );

    final vocabulary = language == 'en' ? CsvVocabulary.en : CsvVocabulary.es;
    final tempDir = await getTemporaryDirectory();
    final today = clock.now();
    final stamp =
        '${today.year.toString().padLeft(4, '0')}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';

    var processedOffset = 0;
    var totalOffset = 0;
    void reportProgress(int processed, int? total) {
      if (isClosed) {
        return;
      }
      emit(
        state.copyWith(
          processed: processedOffset + processed,
          total: totalOffset + (total ?? 0),
        ),
      );
    }

    final writtenPaths = <String>[];
    try {
      if (scope.includeTransactions) {
        final path = p.join(tempDir.path, 'billetudo-transacciones-$stamp.csv');
        final result = await _exportTransactionsCsv(
          outputPath: path,
          scope: scope,
          language: vocabulary.language,
          onProgress: reportProgress,
          cancellationToken: token,
        );
        if (result case Left(value: final failure)) {
          return _fail(failure);
        }
        writtenPaths.add(path);
        processedOffset = state.processed;
        totalOffset = state.total;
      }

      if (scope.includeAccounts || scope.includeCategories) {
        final accountsPath = scope.includeAccounts
            ? p.join(tempDir.path, 'billetudo-cuentas-$stamp.csv')
            : null;
        final categoriesPath = scope.includeCategories
            ? p.join(tempDir.path, 'billetudo-categorias-$stamp.csv')
            : null;
        final result = await _exportAccountsCategoriesCsv(
          accountsOutputPath: accountsPath,
          categoriesOutputPath: categoriesPath,
          language: vocabulary.language,
          onProgress: reportProgress,
          cancellationToken: token,
        );
        if (result case Left(value: final failure)) {
          return _fail(failure);
        }
        if (accountsPath != null) {
          writtenPaths.add(accountsPath);
        }
        if (categoriesPath != null) {
          writtenPaths.add(categoriesPath);
        }
      }

      if (isClosed) {
        return;
      }

      final resultPath = writtenPaths.length == 1
          ? writtenPaths.single
          : await _zip(writtenPaths, tempDir.path, stamp);

      emit(
        state.copyWith(
          runStatus: ExportRunStatus.done,
          resultFilePath: resultPath,
        ),
      );
    } catch (e) {
      if (!isClosed) {
        emit(state.copyWith(runStatus: ExportRunStatus.error));
      }
    } finally {
      _cancellationToken = null;
    }
  }

  /// Stops the running export at the next row boundary (HU-01/HU-09): the
  /// partial file is deleted by the same `abort()` path a write failure uses,
  /// and [ExportState.runStatus] becomes `cancelled` rather than `error` so
  /// the UI does not blame the user for choosing to stop.
  void cancel() => _cancellationToken?.cancel();

  Future<String> _zip(
    List<String> paths,
    String tempDirPath,
    String stamp,
  ) async {
    // Deletes the loose files and writes the archive — orchestrated here
    // because it needs to know about every file this cubit wrote across two
    // use cases, which neither of them individually touches (HU-02).
    final zipPath = p.join(tempDirPath, 'billetudo-export-$stamp.zip');
    final result =
        await _zipExportFiles(outputPath: zipPath, inputPaths: paths);
    if (result case Left(value: final failure)) {
      _fail(failure);
    }
    return zipPath;
  }

  void _fail(Failure failure) {
    if (isClosed) {
      return;
    }
    final cancelled =
        failure is IoFailure && failure.reason == IoFailureReason.cancelled;
    emit(
      state.copyWith(
        runStatus:
            cancelled ? ExportRunStatus.cancelled : ExportRunStatus.error,
        failure: cancelled ? null : failure,
      ),
    );
  }

  /// Hands [path] to the system share sheet (HU-01: "sin pedir permisos de
  /// almacenamiento donde el share nativo baste") and clears the pending
  /// result once done.
  Future<void> shareResult(String path) async {
    await SharePlus.instance.share(
      ShareParams(files: [XFile(path)]),
    );
    if (!isClosed) {
      emit(state.copyWith(clearResult: true, runStatus: ExportRunStatus.idle));
    }
  }

  void dismissError() {
    if (!isClosed) {
      emit(state.copyWith(runStatus: ExportRunStatus.idle));
    }
  }
}
