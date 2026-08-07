import 'package:drift/drift.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/database/app_database.dart' as db;
import '../../domain/entities/cancellation_token.dart';
import '../../domain/entities/import_commit_plan.dart';
import '../../domain/entities/import_destination.dart';
import '../../domain/entities/import_entry_type.dart';
import '../../domain/entities/progress_callback.dart';
import '../../domain/entities/undo_summary.dart';

/// New accounts an import creates with no currency of their own in the file
/// default here — same market default the rest of the app assumes when
/// nothing else is known.
const String _defaultNewAccountCurrency = 'COP';

/// Drift writes for HU-05/06/08: commits a finished import (creating every
/// destination a row needs, in one transaction) and reverts a batch. Kept
/// separate from `ImportDestinationsLocalDatasource` (reads only, never a
/// write transaction).
@lazySingleton
class ImportBatchesLocalDatasource {
  const ImportBatchesLocalDatasource(this._db);

  final db.AppDatabase _db;

  Stream<List<db.ImportBatche>> watchBatches() => (_db.select(_db.importBatches)
        ..orderBy([(b) => OrderingTerm.desc(b.importedAt)]))
      .watch();

  Future<db.ImportBatche?> getBatch(String id) =>
      (_db.select(_db.importBatches)..where((b) => b.id.equals(id)))
          .getSingleOrNull();

  /// HU-05/06/08: creates the batch row, every `NewImportDestination` the
  /// plan's rows need (accounts, root/subcategories, tags), and every row as
  /// a `source = imported` transaction stamped with the new
  /// `importBatchId` — all inside one transaction.
  Future<db.ImportBatche> commitImport(
    ImportCommitPlan plan, {
    ProgressCallback? onProgress,
    CancellationToken? cancellationToken,
  }) =>
      _db.transaction(() async {
        final now = DateTime.now();
        final batch = await _db.into(_db.importBatches).insertReturning(
              db.ImportBatchesCompanion.insert(
                fileName: plan.fileName,
                templateName: Value(plan.templateName),
                importedAt: now,
                rowsImported: plan.rows.length,
                rowsSkipped: plan.skippedDuplicateCount + plan.skippedErrorCount,
                createdAt: Value(now),
                updatedAt: Value(now.millisecondsSinceEpoch),
              ),
            );

        final accountIds = <String, String>{};
        final accountCurrencies = <String, String>{};
        final rootCategoryIds = <String, String>{};
        final subcategoryIds = <String, String>{};
        final tagIds = <String, String>{};

        Future<String?> resolveAccount(
          ImportDestination? destination,
          String? currencyHint,
        ) async {
          switch (destination) {
            case null:
              return null;
            case ExistingImportDestination(:final id):
              if (!accountCurrencies.containsKey(id)) {
                final row = await (_db.select(_db.accounts)
                      ..where((a) => a.id.equals(id)))
                    .getSingleOrNull();
                accountCurrencies[id] = row?.currency ?? _defaultNewAccountCurrency;
              }
              return id;
            case NewImportDestination(:final name):
              final key = name.toLowerCase();
              final cached = accountIds[key];
              if (cached != null) {
                return cached;
              }
              final currency = currencyHint ?? _defaultNewAccountCurrency;
              final row = await _db.into(_db.accounts).insertReturning(
                    db.AccountsCompanion.insert(
                      name: name,
                      type: db.AccountType.other,
                      currency: currency,
                      initialBalanceMinor: const Value(0),
                      createdAt: Value(now),
                      updatedAt: Value(now.millisecondsSinceEpoch),
                      importBatchId: Value(batch.id),
                    ),
                  );
              accountIds[key] = row.id;
              accountCurrencies[row.id] = currency;
              return row.id;
          }
        }

        Future<String?> resolveRootCategory(
          ImportDestination? destination,
          db.CategoryKind kind,
        ) async {
          switch (destination) {
            case null:
              return null;
            case ExistingImportDestination(:final id):
              return id;
            case NewImportDestination(:final name):
              final key = '${kind.name}:${name.toLowerCase()}';
              final cached = rootCategoryIds[key];
              if (cached != null) {
                return cached;
              }
              final row = await _db.into(_db.categories).insertReturning(
                    db.CategoriesCompanion.insert(
                      name: name,
                      kind: kind,
                      createdAt: Value(now),
                      updatedAt: Value(now.millisecondsSinceEpoch),
                      importBatchId: Value(batch.id),
                    ),
                  );
              rootCategoryIds[key] = row.id;
              return row.id;
          }
        }

        Future<String?> resolveSubcategory(
          ImportDestination? destination,
          String? parentId,
          db.CategoryKind kind,
        ) async {
          if (parentId == null) {
            return null;
          }
          switch (destination) {
            case null:
              return null;
            case ExistingImportDestination(:final id):
              return id;
            case NewImportDestination(:final name):
              final key = '$parentId/${name.toLowerCase()}';
              final cached = subcategoryIds[key];
              if (cached != null) {
                return cached;
              }
              final row = await _db.into(_db.categories).insertReturning(
                    db.CategoriesCompanion.insert(
                      name: name,
                      kind: kind,
                      parentId: Value(parentId),
                      createdAt: Value(now),
                      updatedAt: Value(now.millisecondsSinceEpoch),
                      importBatchId: Value(batch.id),
                    ),
                  );
              subcategoryIds[key] = row.id;
              return row.id;
          }
        }

        Future<String> resolveTag(ImportDestination destination) async {
          switch (destination) {
            case ExistingImportDestination(:final id):
              return id;
            case NewImportDestination(:final name):
              final key = name.toLowerCase();
              final cached = tagIds[key];
              if (cached != null) {
                return cached;
              }
              final row = await _db.into(_db.tags).insertReturning(
                    db.TagsCompanion.insert(
                      name: name,
                      createdAt: Value(now),
                      updatedAt: Value(now.millisecondsSinceEpoch),
                      importBatchId: Value(batch.id),
                    ),
                  );
              tagIds[key] = row.id;
              return row.id;
          }
        }

        final totalRows = plan.rows.length;
        onProgress?.call(0, totalRows);
        for (var i = 0; i < totalRows; i++) {
          if (cancellationToken?.isCancelled ?? false) {
            // Thrown inside `_db.transaction()`'s callback, which rolls the
            // whole write back — no row is left half-written (HU-05).
            throw const OperationCancelledException();
          }
          final row = plan.rows[i];
          final kind = row.type == ImportEntryType.expense
              ? db.CategoryKind.expense
              : db.CategoryKind.income;

          final accountId =
              await resolveAccount(row.accountDestination, row.currency);
          if (accountId == null) {
            // A `valid`/duplicate row always has an account by construction
            // (`account` is a required mapped field) — defensive only.
            continue;
          }
          final transferAccountId = row.type == ImportEntryType.transfer
              ? await resolveAccount(row.transferAccountDestination, row.currency)
              : null;
          final categoryId = row.type == ImportEntryType.transfer
              ? null
              : await resolveRootCategory(row.categoryDestination, kind);
          final subcategoryId = row.type == ImportEntryType.transfer
              ? null
              : await resolveSubcategory(
                  row.subcategoryDestination,
                  categoryId,
                  kind,
                );

          final currency = row.currency ?? accountCurrencies[accountId] ?? _defaultNewAccountCurrency;

          final transaction = await _db.into(_db.transactions).insertReturning(
                db.TransactionsCompanion.insert(
                  accountId: accountId,
                  amountMinor: row.amountMinor!.abs(),
                  currency: currency,
                  type: _entryTypeToDb(row.type!),
                  date: row.date!,
                  categoryId: Value(subcategoryId ?? categoryId),
                  note: Value(row.note),
                  source: const Value(db.TxSource.imported),
                  transferAccountId: Value(transferAccountId),
                  createdAt: Value(now),
                  updatedAt: Value(now.millisecondsSinceEpoch),
                  importBatchId: Value(batch.id),
                ),
              );

          for (final tagDestination in row.tagDestinations) {
            final tagId = await resolveTag(tagDestination);
            await _db.into(_db.transactionTags).insert(
                  db.TransactionTagsCompanion.insert(
                    transactionId: transaction.id,
                    tagId: tagId,
                    createdAt: Value(now),
                    updatedAt: Value(now.millisecondsSinceEpoch),
                  ),
                );
          }
          onProgress?.call(i + 1, totalRows);
        }

        return batch;
      });

  /// HU-08: trashes (`deletedAt`) every transaction the batch created, plus
  /// every account/category/tag it created that has **no use outside it** —
  /// "used outside" means referenced by a live row this batch did not create
  /// (a manual transaction pointing at an account the import made, another
  /// transaction using a category the import made, etc). Rows that *are*
  /// used elsewhere are kept, never trashed. All inside one transaction.
  Future<UndoSummary> undoBatch(String batchId) => _db.transaction(() async {
        final now = DateTime.now();

        final batchTransactions = await (_db.select(_db.transactions)
              ..where(
                (t) => t.importBatchId.equals(batchId) & t.deletedAt.isNull(),
              ))
            .get();

        var manuallyEdited = 0;
        for (final t in batchTransactions) {
          // A row this batch created still carries `source = imported`; if the
          // user later edited it by hand the repository stamped a new
          // `updatedAt` but never changes `source` — so "edited after import"
          // is detected by `updatedAt` having moved past `createdAt` by more
          // than clock jitter would explain on the same write.
          if (t.updatedAt > t.createdAt.millisecondsSinceEpoch + 1000) {
            manuallyEdited++;
          }
          await (_db.update(_db.transactions)..where((row) => row.id.equals(t.id)))
              .write(
            db.TransactionsCompanion(
              deletedAt: Value(now),
              updatedAt: Value(now.millisecondsSinceEpoch),
            ),
          );
        }

        final accountResult = await _trashUnusedAccounts(batchId, now);
        final categoryResult = await _trashUnusedCategories(batchId, now);
        final tagResult = await _trashUnusedTags(batchId, now);

        await (_db.update(_db.importBatches)..where((b) => b.id.equals(batchId)))
            .write(
          db.ImportBatchesCompanion(
            revertedAt: Value(now),
            updatedAt: Value(now.millisecondsSinceEpoch),
          ),
        );

        return UndoSummary(
          transactionsTrashed: batchTransactions.length,
          accountsTrashed: accountResult.trashed,
          accountsKept: accountResult.kept,
          categoriesTrashed: categoryResult.trashed,
          categoriesKept: categoryResult.kept,
          tagsTrashed: tagResult.trashed,
          tagsKept: tagResult.kept,
          manuallyEditedRowsTrashed: manuallyEdited,
        );
      });

  Future<({int trashed, int kept})> _trashUnusedAccounts(
    String batchId,
    DateTime now,
  ) async {
    final created = await (_db.select(_db.accounts)
          ..where((a) => a.importBatchId.equals(batchId)))
        .get();
    var trashed = 0;
    var kept = 0;
    for (final account in created) {
      final usedElsewhere = await _accountUsedOutsideBatch(account.id, batchId);
      if (usedElsewhere) {
        kept++;
        continue;
      }
      // Accounts have no `deletedAt` trash flow (HU-08 of `01-cuentas.md`):
      // an unused import-created account is tombstoned, same as any other
      // account deletion.
      await (_db.update(_db.accounts)..where((a) => a.id.equals(account.id)))
          .write(
        db.AccountsCompanion(
          tombstonedAt: Value(now),
          updatedAt: Value(now.millisecondsSinceEpoch),
        ),
      );
      trashed++;
    }
    return (trashed: trashed, kept: kept);
  }

  /// `col != batchId` is NULL (not TRUE) in SQL when `col IS NULL` — which is
  /// exactly every manually-created row, the most common case this method
  /// exists to protect. Without the explicit `isNull()` branch, every
  /// manually-created transaction would silently fail to count as "used
  /// outside the batch" and its account/category/tag would be wrongly
  /// trashed on undo (HU-08).
  Expression<bool> _notThisBatch(
    GeneratedColumn<String> importBatchId,
    String batchId,
  ) =>
      importBatchId.isNull() | importBatchId.equals(batchId).not();

  Future<bool> _accountUsedOutsideBatch(String accountId, String batchId) async {
    final count = _db.transactions.id.count();
    final query = _db.selectOnly(_db.transactions)
      ..addColumns([count])
      ..where(
        (_db.transactions.accountId.equals(accountId) |
                _db.transactions.transferAccountId.equals(accountId)) &
            _db.transactions.deletedAt.isNull() &
            _notThisBatch(_db.transactions.importBatchId, batchId),
      );
    final result = await query.map((row) => row.read(count) ?? 0).getSingle();
    return result > 0;
  }

  /// Two passes on purpose: a root category the batch also created its own
  /// subcategory under must not be judged "unused" just because that
  /// subcategory still exists — the subcategory's own outcome (kept or
  /// trashed) has to be decided first, then propagated up to the root, or an
  /// undo could orphan a subcategory whose parent just got trashed under it.
  /// Two levels only, matching `Category.isRoot` — the hierarchy never nests
  /// deeper (`features/categories/domain/entities/category.dart`).
  Future<({int trashed, int kept})> _trashUnusedCategories(
    String batchId,
    DateTime now,
  ) async {
    final created = await (_db.select(_db.categories)
          ..where((c) => c.importBatchId.equals(batchId)))
        .get();
    final createdIds = created.map((c) => c.id).toSet();

    final keep = <String>{};
    for (final category in created) {
      if (await _categoryDirectlyUsedOutsideBatch(category.id, batchId, createdIds)) {
        keep.add(category.id);
      }
    }
    for (final category in created) {
      final parentId = category.parentId;
      if (keep.contains(category.id) && parentId != null && createdIds.contains(parentId)) {
        keep.add(parentId);
      }
    }

    var trashed = 0;
    var kept = 0;
    for (final category in created) {
      if (keep.contains(category.id)) {
        kept++;
        continue;
      }
      await (_db.update(_db.categories)..where((c) => c.id.equals(category.id)))
          .write(
        db.CategoriesCompanion(
          deletedAt: Value(now),
          updatedAt: Value(now.millisecondsSinceEpoch),
        ),
      );
      trashed++;
    }
    return (trashed: trashed, kept: kept);
  }

  /// "Directly used" = a live transaction outside the batch references it, or
  /// a live subcategory the batch did **not** create points at it (an
  /// existing subcategory, or one from a different import) — a subcategory
  /// the batch created under it is deliberately excluded here; that case is
  /// resolved by [_trashUnusedCategories]'s propagation pass instead.
  Future<bool> _categoryDirectlyUsedOutsideBatch(
    String categoryId,
    String batchId,
    Set<String> createdByThisBatch,
  ) async {
    final txCount = _db.transactions.id.count();
    final txQuery = _db.selectOnly(_db.transactions)
      ..addColumns([txCount])
      ..where(
        _db.transactions.categoryId.equals(categoryId) &
            _db.transactions.deletedAt.isNull() &
            _notThisBatch(_db.transactions.importBatchId, batchId),
      );
    final txUsage = await txQuery.map((row) => row.read(txCount) ?? 0).getSingle();
    if (txUsage > 0) {
      return true;
    }
    final subCount = _db.categories.id.count();
    final subQuery = _db.selectOnly(_db.categories)
      ..addColumns([subCount])
      ..where(
        _db.categories.parentId.equals(categoryId) &
            _db.categories.deletedAt.isNull() &
            _db.categories.tombstonedAt.isNull() &
            _notThisBatch(_db.categories.importBatchId, batchId),
      );
    final subUsage = await subQuery.map((row) => row.read(subCount) ?? 0).getSingle();
    return subUsage > 0;
  }

  Future<({int trashed, int kept})> _trashUnusedTags(
    String batchId,
    DateTime now,
  ) async {
    final created =
        await (_db.select(_db.tags)..where((t) => t.importBatchId.equals(batchId)))
            .get();
    var trashed = 0;
    var kept = 0;
    for (final tag in created) {
      final count = _db.transactionTags.id.count();
      final query = _db.selectOnly(_db.transactionTags).join([
        innerJoin(
          _db.transactions,
          _db.transactions.id.equalsExp(_db.transactionTags.transactionId),
        ),
      ])
        ..addColumns([count])
        ..where(
          _db.transactionTags.tagId.equals(tag.id) &
              _db.transactionTags.deletedAt.isNull() &
              _db.transactions.deletedAt.isNull() &
              _notThisBatch(_db.transactions.importBatchId, batchId),
        );
      final usage = await query.map((row) => row.read(count) ?? 0).getSingle();
      if (usage > 0) {
        kept++;
        continue;
      }
      await (_db.update(_db.tags)..where((t) => t.id.equals(tag.id))).write(
        db.TagsCompanion(
          deletedAt: Value(now),
          updatedAt: Value(now.millisecondsSinceEpoch),
        ),
      );
      trashed++;
    }
    return (trashed: trashed, kept: kept);
  }

  db.EntryType _entryTypeToDb(ImportEntryType type) => switch (type) {
        ImportEntryType.income => db.EntryType.income,
        ImportEntryType.expense => db.EntryType.expense,
        ImportEntryType.transfer => db.EntryType.transfer,
      };
}
