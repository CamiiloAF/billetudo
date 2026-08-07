import 'package:injectable/injectable.dart';

import '../../../../core/error/result.dart';
import '../entities/column_mapping.dart';
import '../entities/csv_dialect.dart';
import '../entities/import_destination.dart';
import '../entities/import_entry_type.dart';
import '../entities/import_preview.dart';
import '../entities/import_preview_row.dart';
import '../entities/named_entity.dart';
import '../entities/parsed_import_row.dart';
import '../repositories/import_repository.dart';
import '../utils/text_normalizer.dart';

/// HU-06: resolves destinations, detects duplicates and validates every row
/// of `filePath`, entirely from what already exists locally plus `mapping`/
/// `dialect`. Nothing is written — that is `ConfirmImport`'s job.
///
/// `accountOverrides`/`categoryOverrides`/`subcategoryOverrides`/
/// `tagOverrides` let the "resolver destinos" step (HU-06, screen `kYBYa`)
/// force a name to a specific existing row or to "create new" even against
/// the autodetected fuzzy match — keyed by [normalizeForMatching] of the raw
/// name (subcategories keyed by `"<normalized root>/<normalized leaf>"`, so
/// the same leaf name under two different roots does not collide).
@injectable
class PreviewImport {
  const PreviewImport(this._repository);

  final ImportRepository _repository;

  FutureResult<ImportPreview> call({
    required String filePath,
    required ColumnMapping mapping,
    required CsvDialect dialect,
    Map<String, ImportDestination> accountOverrides = const {},
    Map<String, ImportDestination> categoryOverrides = const {},
    Map<String, ImportDestination> subcategoryOverrides = const {},
    Map<String, ImportDestination> tagOverrides = const {},
  }) async {
    if (!mapping.isComplete) {
      return const Left(
        ValidationFailure(
          'the mapping is missing a required field (fecha/monto/cuenta)',
          field: 'mapping',
        ),
      );
    }

    final rowsResult =
        await _repository.readAllRows(filePath, dialect: dialect);
    if (rowsResult case Left(value: final failure)) {
      return Left(failure);
    }
    final rawRows = (rowsResult as Right<Failure, List<List<String>>>).value;

    final parsedRows = <ParsedImportRow>[
      for (var i = 0; i < rawRows.length; i++)
        _repository.parseRow(
          rawRows[i],
          rowNumber: i + 1,
          mapping: mapping,
          dialect: dialect,
        ),
    ];

    final existingAccountsResult = await _repository.getExistingAccounts();
    if (existingAccountsResult case Left(value: final failure)) {
      return Left(failure);
    }
    final existingAccounts =
        (existingAccountsResult as Right<Failure, List<NamedEntity>>).value;

    final existingTagsResult = await _repository.getExistingTags();
    if (existingTagsResult case Left(value: final failure)) {
      return Left(failure);
    }
    final existingTags =
        (existingTagsResult as Right<Failure, List<NamedEntity>>).value;

    final expenseRootsResult =
        await _repository.getExistingRootCategories(isExpense: true);
    final incomeRootsResult =
        await _repository.getExistingRootCategories(isExpense: false);
    if (expenseRootsResult case Left(value: final failure)) {
      return Left(failure);
    }
    if (incomeRootsResult case Left(value: final failure)) {
      return Left(failure);
    }
    final expenseRoots =
        (expenseRootsResult as Right<Failure, List<NamedEntity>>).value;
    final incomeRoots =
        (incomeRootsResult as Right<Failure, List<NamedEntity>>).value;

    final subcategoryCache = <String, List<NamedEntity>>{};

    // -- Pass 1: resolve every destination, exact-duplicate ids, probable
    // duplicate signatures. --
    final accountDestinations = <String, ImportDestination>{};
    final transferDestinations = <String, ImportDestination>{};
    final categoryDestinations = <String, ImportDestination>{};
    final subcategoryDestinations = <String, ImportDestination>{};
    final tagDestinations = <String, ImportDestination>{};
    final sourceIds = <String>{};

    for (final row in parsedRows) {
      if (!row.isParseValid) {
        continue;
      }
      if (row.sourceId != null) {
        sourceIds.add(row.sourceId!);
      }
      if (row.accountName != null) {
        _resolveNamed(
          row.accountName!,
          existing: existingAccounts,
          overrides: accountOverrides,
          into: accountDestinations,
        );
      }
      if (row.transferAccountName != null) {
        _resolveNamed(
          row.transferAccountName!,
          existing: existingAccounts,
          overrides: accountOverrides,
          into: transferDestinations,
        );
      }
      if (row.type != ImportEntryType.transfer && row.categoryName != null) {
        final roots =
            row.type == ImportEntryType.expense ? expenseRoots : incomeRoots;
        _resolveNamed(
          row.categoryName!,
          existing: roots,
          overrides: categoryOverrides,
          into: categoryDestinations,
        );
        // Subcategories are resolved in the pass below, once every root is
        // known and its existing subcategories have been fetched — a root
        // this loop just marked `NewImportDestination` cannot be queried yet.
      }
      for (final tag in row.tags) {
        _resolveNamed(
          tag,
          existing: existingTags,
          overrides: tagOverrides,
          into: tagDestinations,
        );
      }
    }

    // Subcategories need each root's existing subcategories fetched once,
    // which needs every root resolved first — hence this separate pass.
    for (final destination in categoryDestinations.values) {
      if (destination is ExistingImportDestination &&
          !subcategoryCache.containsKey(destination.id)) {
        final result =
            await _repository.getExistingSubcategories(destination.id);
        if (result case Left(value: final failure)) {
          return Left(failure);
        }
        subcategoryCache[destination.id] =
            (result as Right<Failure, List<NamedEntity>>).value;
      }
    }
    for (final row in parsedRows) {
      if (!row.isParseValid ||
          row.type == ImportEntryType.transfer ||
          row.categoryName == null ||
          row.subcategoryName == null) {
        continue;
      }
      final rootKey = normalizeForMatching(row.categoryName!);
      final subKey = '$rootKey/${normalizeForMatching(row.subcategoryName!)}';
      if (subcategoryDestinations.containsKey(subKey)) {
        continue;
      }
      final override = subcategoryOverrides[subKey];
      if (override != null) {
        subcategoryDestinations[subKey] = override;
        continue;
      }
      final rootDestination = categoryDestinations[rootKey];
      if (rootDestination is ExistingImportDestination) {
        final existingSubs = subcategoryCache[rootDestination.id] ?? const [];
        final match = _findMatch(row.subcategoryName!, existingSubs);
        subcategoryDestinations[subKey] = match != null
            ? ExistingImportDestination(match.id)
            : NewImportDestination(row.subcategoryName!, parentName: row.categoryName);
      } else {
        subcategoryDestinations[subKey] =
            NewImportDestination(row.subcategoryName!, parentName: row.categoryName);
      }
    }

    final existingIdsResult =
        await _repository.findExistingTransactionIds(sourceIds);
    if (existingIdsResult case Left(value: final failure)) {
      return Left(failure);
    }
    final existingIds =
        (existingIdsResult as Right<Failure, Set<String>>).value;

    final signatureByRow = <int, ProbableDuplicateSignature>{};
    final candidateSignatures = <ProbableDuplicateSignature>{};
    for (final row in parsedRows) {
      if (!row.isParseValid ||
          row.sourceId != null ||
          row.currency == null ||
          row.date == null ||
          row.amountMinor == null ||
          row.type == null ||
          row.accountName == null) {
        continue;
      }
      final accountDestination =
          accountDestinations[normalizeForMatching(row.accountName!)];
      if (accountDestination is! ExistingImportDestination) {
        // A brand new account cannot already have a transaction to collide
        // with.
        continue;
      }
      final signature = ProbableDuplicateSignature(
        accountId: accountDestination.id,
        amountMinor: row.amountMinor!,
        currency: row.currency!.toUpperCase(),
        type: row.type!.name,
        date: DateTime(row.date!.year, row.date!.month, row.date!.day),
      );
      signatureByRow[row.rowNumber] = signature;
      candidateSignatures.add(signature);
    }
    final probableResult =
        await _repository.findProbableDuplicates(candidateSignatures);
    if (probableResult case Left(value: final failure)) {
      return Left(failure);
    }
    final probableMatches = (probableResult
            as Right<Failure, Set<ProbableDuplicateSignature>>)
        .value;

    // -- Pass 2: build the final preview rows. --
    final previewRows = <ImportPreviewRow>[
      for (final row in parsedRows)
        _toPreviewRow(
          row,
          existingIds: existingIds,
          signatureByRow: signatureByRow,
          probableMatches: probableMatches,
          accountDestinations: accountDestinations,
          transferDestinations: transferDestinations,
          categoryDestinations: categoryDestinations,
          subcategoryDestinations: subcategoryDestinations,
          tagDestinations: tagDestinations,
        ),
    ];

    return Right(ImportPreview(rows: previewRows));
  }

  void _resolveNamed(
    String name, {
    required List<NamedEntity> existing,
    required Map<String, ImportDestination> overrides,
    required Map<String, ImportDestination> into,
  }) {
    final key = normalizeForMatching(name);
    if (into.containsKey(key)) {
      return;
    }
    final override = overrides[key];
    if (override != null) {
      into[key] = override;
      return;
    }
    final match = _findMatch(name, existing);
    into[key] =
        match != null ? ExistingImportDestination(match.id) : NewImportDestination(name);
  }

  NamedEntity? _findMatch(String name, List<NamedEntity> candidates) {
    final key = normalizeForMatching(name);
    for (final candidate in candidates) {
      if (normalizeForMatching(candidate.name) == key) {
        return candidate;
      }
    }
    return null;
  }

  ImportPreviewRow _toPreviewRow(
    ParsedImportRow row, {
    required Set<String> existingIds,
    required Map<int, ProbableDuplicateSignature> signatureByRow,
    required Set<ProbableDuplicateSignature> probableMatches,
    required Map<String, ImportDestination> accountDestinations,
    required Map<String, ImportDestination> transferDestinations,
    required Map<String, ImportDestination> categoryDestinations,
    required Map<String, ImportDestination> subcategoryDestinations,
    required Map<String, ImportDestination> tagDestinations,
  }) {
    if (!row.isParseValid) {
      return ImportPreviewRow(
        rowNumber: row.rowNumber,
        status: ImportRowStatus.invalid,
        includedByDefault: false,
        invalidIssue: row.issue,
      );
    }

    final ImportRowStatus status;
    if (row.sourceId != null && existingIds.contains(row.sourceId)) {
      status = ImportRowStatus.duplicateExact;
    } else if (signatureByRow[row.rowNumber] != null &&
        probableMatches.contains(signatureByRow[row.rowNumber])) {
      status = ImportRowStatus.duplicateProbable;
    } else {
      status = ImportRowStatus.valid;
    }

    final accountKey =
        row.accountName == null ? null : normalizeForMatching(row.accountName!);
    final transferKey = row.transferAccountName == null
        ? null
        : normalizeForMatching(row.transferAccountName!);
    final categoryKey =
        row.categoryName == null ? null : normalizeForMatching(row.categoryName!);
    final subcategoryKey = categoryKey == null || row.subcategoryName == null
        ? null
        : '$categoryKey/${normalizeForMatching(row.subcategoryName!)}';

    return ImportPreviewRow(
      rowNumber: row.rowNumber,
      status: status,
      includedByDefault: status == ImportRowStatus.valid,
      sourceId: row.sourceId,
      date: row.date,
      dateAmbiguous: row.dateAmbiguous,
      amountMinor: row.amountMinor,
      amountRounded: row.amountRounded,
      type: row.type,
      currency: row.currency,
      accountDestination: accountKey == null ? null : accountDestinations[accountKey],
      transferAccountDestination:
          transferKey == null ? null : transferDestinations[transferKey],
      categoryDestination: categoryKey == null ? null : categoryDestinations[categoryKey],
      subcategoryDestination:
          subcategoryKey == null ? null : subcategoryDestinations[subcategoryKey],
      note: row.note,
      tags: row.tags,
      tagDestinations: [
        for (final tag in row.tags) tagDestinations[normalizeForMatching(tag)]!,
      ],
    );
  }
}
