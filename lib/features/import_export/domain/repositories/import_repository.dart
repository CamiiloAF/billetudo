import '../../../../core/error/result.dart';
import '../entities/cancellation_token.dart';
import '../entities/column_mapping.dart';
import '../entities/csv_dialect.dart';
import '../entities/import_batch.dart';
import '../entities/import_commit_plan.dart';
import '../entities/named_entity.dart';
import '../entities/parsed_csv_sample.dart';
import '../entities/parsed_import_row.dart';
import '../entities/progress_callback.dart';

/// A candidate duplicate signature for a row with no `id` (HU-07): same
/// account + amount + currency + type + date as an existing transaction.
class ProbableDuplicateSignature {
  const ProbableDuplicateSignature({
    required this.accountId,
    required this.amountMinor,
    required this.currency,
    required this.type,
    required this.date,
  });

  final String accountId;
  final int amountMinor;
  final String currency;

  /// `income`/`expense`/`transfer`, as text — kept loosely typed here so this
  /// signature does not need to import `ImportEntryType` just to be a map
  /// key; the repository implementation is the only place that builds and
  /// compares it.
  final String type;

  /// Date-only (time truncated), local device timezone — same rule as
  /// `10-graficas-informes.md` §Reglas de conteo.
  final DateTime date;

  @override
  bool operator ==(Object other) =>
      other is ProbableDuplicateSignature &&
      other.accountId == accountId &&
      other.amountMinor == amountMinor &&
      other.currency == currency &&
      other.type == type &&
      other.date == date;

  @override
  int get hashCode => Object.hash(accountId, amountMinor, currency, type, date);
}

/// HU-05/06/07/08: everything Import needs from Drift. Column-mapping
/// decisions, duplicate/status classification and destination resolution are
/// domain logic (`PreviewImport`/`ConfirmImport`); this interface only reads
/// candidates and writes the final, already-decided plan.
abstract class ImportRepository {
  /// Reads the header row, a data-row sample and detects [CsvDialect] for
  /// [filePath] (HU-05). Fails with `IoFailure` when the file is not
  /// readable/decodable CSV or has no rows.
  FutureResult<ParsedCsvSample> readCsvSample(String filePath);

  /// Reads every data row of [filePath] using [dialect] (HU-06 preview needs
  /// the full file, not just the sample `readCsvSample` returned).
  FutureResult<List<List<String>>> readAllRows(
    String filePath, {
    required CsvDialect dialect,
  });

  /// Parses one raw row into typed domain values using [mapping]/[dialect].
  /// Sync and side-effect free: decimal/date parsing (exact integer
  /// arithmetic, half-up rounding — never `double`) is implemented in
  /// `data/`, but the parsed *result* is a pure domain value.
  ParsedImportRow parseRow(
    List<String> rawCells, {
    required int rowNumber,
    required ColumnMapping mapping,
    required CsvDialect dialect,
  });

  /// Active (non-tombstoned) accounts, for destination matching (HU-06).
  FutureResult<List<NamedEntity>> getExistingAccounts();

  /// Active (non-deleted, non-tombstoned) root categories of the given kind.
  FutureResult<List<NamedEntity>> getExistingRootCategories({
    required bool isExpense,
  });

  /// Active subcategories of [parentId].
  FutureResult<List<NamedEntity>> getExistingSubcategories(String parentId);

  FutureResult<List<NamedEntity>> getExistingTags();

  /// Of [ids], which already exist as a non-deleted, non-tombstoned
  /// transaction (HU-07 exact duplicate). Runs as a single `WHERE id IN
  /// (...)`, never a per-row query.
  FutureResult<Set<String>> findExistingTransactionIds(Set<String> ids);

  /// Of [signatures], which already match an existing, non-deleted,
  /// non-tombstoned transaction (HU-07 probable duplicate). Indexed SQL, not
  /// an in-memory scan.
  FutureResult<Set<ProbableDuplicateSignature>> findProbableDuplicates(
    Set<ProbableDuplicateSignature> signatures,
  );

  /// HU-05/06/08: writes the batch row, every destination
  /// `NewImportDestination` needs created, and every row in [plan] as a
  /// `Transaction` stamped `source = imported` + the new `importBatchId` —
  /// all inside one transaction.
  ///
  /// [onProgress] fires after every row of [plan] is written
  /// (`processed`/`plan.rows.length`). [cancellationToken] stops the write at
  /// the next row boundary; because this whole write is one Drift
  /// transaction, cancelling rolls it back — "cancelar no deja filas a
  /// medias" (HU-05) holds by construction, not by manual cleanup.
  FutureResult<ImportBatch> commitImport(
    ImportCommitPlan plan, {
    ProgressCallback? onProgress,
    CancellationToken? cancellationToken,
  });
}
