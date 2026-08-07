import 'package:drift/drift.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/database/app_database.dart';
import '../../domain/repositories/import_repository.dart' show ProbableDuplicateSignature;

/// Read-only Drift queries `PreviewImport` needs (HU-06/07): existing
/// accounts/categories/tags to match a CSV name against, and duplicate
/// detection. Deliberately separate from `ImportBatchesLocalDatasource`,
/// which owns the writes — this one is never inside a write transaction.
@lazySingleton
class ImportDestinationsLocalDatasource {
  const ImportDestinationsLocalDatasource(this._db);

  final AppDatabase _db;

  Future<List<Account>> getActiveAccounts() =>
      (_db.select(_db.accounts)..where((a) => a.tombstonedAt.isNull())).get();

  Future<List<Category>> getActiveRootCategories({required bool isExpense}) =>
      (_db.select(_db.categories)
            ..where(
              (c) =>
                  c.deletedAt.isNull() &
                  c.tombstonedAt.isNull() &
                  c.parentId.isNull() &
                  c.kind.equalsValue(
                    isExpense ? CategoryKind.expense : CategoryKind.income,
                  ),
            ))
          .get();

  Future<List<Category>> getActiveSubcategories(String parentId) =>
      (_db.select(_db.categories)
            ..where(
              (c) =>
                  c.deletedAt.isNull() &
                  c.tombstonedAt.isNull() &
                  c.parentId.equals(parentId),
            ))
          .get();

  Future<List<Tag>> getActiveTags() =>
      (_db.select(_db.tags)..where((t) => t.deletedAt.isNull() & t.tombstonedAt.isNull()))
          .get();

  /// HU-07 exact duplicate: of [ids], which already exist as a live
  /// transaction. A single `WHERE id IN (...)`, never a per-row query.
  Future<Set<String>> findExistingTransactionIds(Set<String> ids) async {
    if (ids.isEmpty) {
      return const {};
    }
    final rows = await (_db.select(_db.transactions)
          ..where(
            (t) =>
                t.id.isIn(ids) & t.deletedAt.isNull() & t.tombstonedAt.isNull(),
          ))
        .get();
    return rows.map((row) => row.id).toSet();
  }

  /// HU-07 probable duplicate: of [signatures], which already match a live
  /// transaction on account + amount + currency + type + date. Runs one query
  /// per distinct account touched by [signatures] (indexed on `accountId`),
  /// never an in-memory scan of the whole history.
  Future<Set<ProbableDuplicateSignature>> findProbableDuplicates(
    Set<ProbableDuplicateSignature> signatures,
  ) async {
    if (signatures.isEmpty) {
      return const {};
    }
    final byAccount = <String, List<ProbableDuplicateSignature>>{};
    for (final signature in signatures) {
      byAccount.putIfAbsent(signature.accountId, () => []).add(signature);
    }

    final matches = <ProbableDuplicateSignature>{};
    for (final entry in byAccount.entries) {
      final rows = await (_db.select(_db.transactions)
            ..where(
              (t) =>
                  t.accountId.equals(entry.key) &
                  t.deletedAt.isNull() &
                  t.tombstonedAt.isNull(),
            ))
          .get();
      final existing = {
        for (final row in rows)
          ProbableDuplicateSignature(
            accountId: row.accountId,
            amountMinor: row.amountMinor,
            currency: row.currency.toUpperCase(),
            type: row.type.name,
            date: DateTime(row.date.year, row.date.month, row.date.day),
          ),
      };
      matches.addAll(
        entry.value.where(existing.contains),
      );
    }
    return matches;
  }
}
