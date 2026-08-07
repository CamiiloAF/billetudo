import '../../../../core/error/result.dart';
import '../entities/cancellation_token.dart';
import '../entities/csv_vocabulary.dart';
import '../entities/export_scope.dart';
import '../entities/progress_callback.dart';

/// HU-01/HU-02: writes CSV files by streaming rows from Drift, one file per
/// kind selected in [ExportScope]. Implemented in `data/` over the same
/// Drift queries the rest of the app already trusts; never exposes Drift
/// types outside it.
abstract class ExportRepository {
  /// Streams every transaction matching [scope] to a new CSV file at
  /// [outputPath] (UTF-8 BOM, RFC 4180, `\r\n`, headers in [language]).
  /// Excludes `deletedAt`/`tombstonedAt` transactions and transactions of
  /// tombstoned accounts; archived accounts' transactions are included.
  /// Returns the number of data rows written.
  ///
  /// [onProgress] fires after every written row with the row count and, once
  /// known, the total. [cancellationToken], when [CancellationToken.cancel]
  /// is called, stops the write on the next row boundary and deletes the
  /// partial file (HU-01: "cancelar borra el archivo parcial") — the result
  /// is `Left(IoFailure(reason: IoFailureReason.cancelled))`.
  FutureResult<int> exportTransactionsCsv({
    required String outputPath,
    required ExportScope scope,
    required CsvLanguage language,
    ProgressCallback? onProgress,
    CancellationToken? cancellationToken,
  });

  /// HU-02: writes `billetudo-cuentas-*.csv`. Never includes
  /// `accountNumberEnc` (which is not even a Drift column — it lives only in
  /// secure storage) nor `userId`. Archived accounts are included with their
  /// flag; tombstoned accounts are excluded.
  FutureResult<int> exportAccountsCsv({
    required String outputPath,
    required CsvLanguage language,
    ProgressCallback? onProgress,
    CancellationToken? cancellationToken,
  });

  /// HU-02: writes `billetudo-categorias-*.csv`.
  FutureResult<int> exportCategoriesCsv({
    required String outputPath,
    required CsvLanguage language,
    ProgressCallback? onProgress,
    CancellationToken? cancellationToken,
  });

  /// HU-02: bundles the files at [inputPaths] into a single `.zip` at
  /// [outputPath] and deletes the loose files, so the share sheet only ever
  /// offers one artifact when more than one kind was selected.
  FutureResult<Unit> zipFiles({
    required String outputPath,
    required List<String> inputPaths,
  });
}
