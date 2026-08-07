import 'package:injectable/injectable.dart';

import '../../../../core/error/result.dart';
import '../../../../core/utils/money_formatter.dart';
import '../../domain/entities/cancellation_token.dart';
import '../../domain/entities/column_mapping.dart';
import '../../domain/entities/csv_dialect.dart';
import '../../domain/entities/import_batch.dart';
import '../../domain/entities/import_commit_plan.dart';
import '../../domain/entities/import_entry_type.dart';
import '../../domain/entities/import_row_issue.dart';
import '../../domain/entities/named_entity.dart';
import '../../domain/entities/parsed_csv_sample.dart';
import '../../domain/entities/parsed_import_row.dart';
import '../../domain/entities/progress_callback.dart';
import '../../domain/repositories/import_repository.dart';
import '../datasources/csv_parser_datasource.dart';
import '../datasources/import_batches_local_datasource.dart';
import '../datasources/import_destinations_local_datasource.dart';
import '../models/csv_date_parser.dart';
import '../models/decimal_amount_parser.dart';
import '../models/import_batch_mapper.dart';

/// Drift + `csv` implementation of [ImportRepository] (HU-05/06/07/08).
@LazySingleton(as: ImportRepository)
class ImportRepositoryImpl implements ImportRepository {
  const ImportRepositoryImpl(
    this._csvParser,
    this._destinations,
    this._batches,
  );

  final CsvParserDatasource _csvParser;
  final ImportDestinationsLocalDatasource _destinations;
  final ImportBatchesLocalDatasource _batches;

  @override
  FutureResult<ParsedCsvSample> readCsvSample(String filePath) =>
      _csvParser.readCsvSample(filePath);

  @override
  FutureResult<List<List<String>>> readAllRows(
    String filePath, {
    required CsvDialect dialect,
  }) =>
      _csvParser.readAllRows(filePath, dialect: dialect);

  @override
  ParsedImportRow parseRow(
    List<String> rawCells, {
    required int rowNumber,
    required ColumnMapping mapping,
    required CsvDialect dialect,
  }) {
    String? cell(ImportField field) {
      final index = mapping.columnFor(field);
      if (index == null || index >= rawCells.length) {
        return null;
      }
      final value = rawCells[index].trim();
      return value.isEmpty ? null : value;
    }

    final accountName = cell(ImportField.account);
    if (accountName == null) {
      return ParsedImportRow(
        rowNumber: rowNumber,
        issue: ImportRowIssue.missingAccount,
      );
    }

    final rawDate = cell(ImportField.date);
    if (rawDate == null) {
      return ParsedImportRow(
        rowNumber: rowNumber,
        accountName: accountName,
        issue: ImportRowIssue.missingDate,
      );
    }
    final parsedDate = CsvDateParser.parse(
      rawDate,
      order: dialect.dateOrder,
      separator: dialect.dateSeparator,
    );
    if (parsedDate == null) {
      return ParsedImportRow(
        rowNumber: rowNumber,
        accountName: accountName,
        issue: ImportRowIssue.invalidDate,
      );
    }

    final rawAmount = cell(ImportField.amount);
    if (rawAmount == null) {
      return ParsedImportRow(
        rowNumber: rowNumber,
        accountName: accountName,
        date: parsedDate.date,
        issue: ImportRowIssue.missingAmount,
      );
    }

    final currency = cell(ImportField.currency)?.toUpperCase();
    // Deliberately not `MoneyFormatter.currencyDecimals` — that is a
    // *display* value (0 for COP) and would silently multiply parsed COP
    // amounts by 100. `amountMinor` is always cents regardless of currency
    // (`CLAUDE.md`: "Dinero: SIEMPRE enteros en unidades menores"), so the
    // CSV's own decimal↔minor-units boundary always uses the storage scale,
    // which `MoneyFormatter.inputDecimals` returns for every currency.
    final storageDecimals = MoneyFormatter.inputDecimals(currency ?? 'USD');
    final decimalConvention = dialect.decimalConvention;
    final parsedAmount = DecimalAmountParser.parse(
      rawAmount,
      convention: decimalConvention,
      currencyDecimals: storageDecimals,
    );
    if (parsedAmount == null) {
      return ParsedImportRow(
        rowNumber: rowNumber,
        accountName: accountName,
        date: parsedDate.date,
        issue: ImportRowIssue.invalidAmount,
      );
    }

    ImportEntryType type;
    if (mapping.hasTypeColumn) {
      final rawType = cell(ImportField.type)?.toLowerCase();
      final values = mapping.typeValues;
      if (rawType == null || values == null) {
        return ParsedImportRow(
          rowNumber: rowNumber,
          accountName: accountName,
          date: parsedDate.date,
          issue: ImportRowIssue.invalidType,
        );
      }
      if (rawType == values.income.toLowerCase()) {
        type = ImportEntryType.income;
      } else if (rawType == values.expense.toLowerCase()) {
        type = ImportEntryType.expense;
      } else if (rawType == values.transfer.toLowerCase()) {
        type = ImportEntryType.transfer;
      } else {
        return ParsedImportRow(
          rowNumber: rowNumber,
          accountName: accountName,
          date: parsedDate.date,
          issue: ImportRowIssue.invalidType,
        );
      }
    } else {
      // §Montos: with no `type` column, the amount's own sign carries the
      // direction (negative = gasto). A transfer cannot be expressed this way.
      type = parsedAmount.minorUnits < 0
          ? ImportEntryType.expense
          : ImportEntryType.income;
    }

    return ParsedImportRow(
      rowNumber: rowNumber,
      sourceId: cell(ImportField.id),
      date: parsedDate.date,
      dateAmbiguous: parsedDate.ambiguous,
      amountMinor: parsedAmount.minorUnits.abs(),
      amountRounded: parsedAmount.rounded,
      type: type,
      currency: currency,
      accountName: accountName,
      transferAccountName:
          type == ImportEntryType.transfer ? cell(ImportField.transferAccount) : null,
      categoryName: type == ImportEntryType.transfer ? null : cell(ImportField.category),
      subcategoryName:
          type == ImportEntryType.transfer ? null : cell(ImportField.subcategory),
      note: cell(ImportField.note),
      tags: cell(ImportField.tags)?.split(';').map((t) => t.trim()).where((t) => t.isNotEmpty).toList() ??
          const [],
    );
  }

  @override
  FutureResult<List<NamedEntity>> getExistingAccounts() async {
    final rows = await _destinations.getActiveAccounts();
    return Right([for (final row in rows) NamedEntity(id: row.id, name: row.name)]);
  }

  @override
  FutureResult<List<NamedEntity>> getExistingRootCategories({
    required bool isExpense,
  }) async {
    final rows = await _destinations.getActiveRootCategories(isExpense: isExpense);
    return Right([for (final row in rows) NamedEntity(id: row.id, name: row.name)]);
  }

  @override
  FutureResult<List<NamedEntity>> getExistingSubcategories(String parentId) async {
    final rows = await _destinations.getActiveSubcategories(parentId);
    return Right([for (final row in rows) NamedEntity(id: row.id, name: row.name)]);
  }

  @override
  FutureResult<List<NamedEntity>> getExistingTags() async {
    final rows = await _destinations.getActiveTags();
    return Right([for (final row in rows) NamedEntity(id: row.id, name: row.name)]);
  }

  @override
  FutureResult<Set<String>> findExistingTransactionIds(Set<String> ids) async {
    final result = await _destinations.findExistingTransactionIds(ids);
    return Right(result);
  }

  @override
  FutureResult<Set<ProbableDuplicateSignature>> findProbableDuplicates(
    Set<ProbableDuplicateSignature> signatures,
  ) async {
    final result = await _destinations.findProbableDuplicates(signatures);
    return Right(result);
  }

  @override
  FutureResult<ImportBatch> commitImport(
    ImportCommitPlan plan, {
    ProgressCallback? onProgress,
    CancellationToken? cancellationToken,
  }) async {
    try {
      final row = await _batches.commitImport(
        plan,
        onProgress: onProgress,
        cancellationToken: cancellationToken,
      );
      return Right(ImportBatchMapper.toEntity(row));
    } on OperationCancelledException {
      return const Left(
        IoFailure('import cancelled', reason: IoFailureReason.cancelled),
      );
    } catch (e, st) {
      return Left(
        DatabaseFailure('could not commit import', cause: e, stackTrace: st),
      );
    }
  }
}
