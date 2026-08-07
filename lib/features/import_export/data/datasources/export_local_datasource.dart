import 'package:drift/drift.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/database/app_database.dart';
import '../../domain/entities/export_scope.dart';
import '../../domain/entities/import_entry_type.dart';

/// How many transaction rows [ExportLocalDatasource.getTransactionsPage]
/// reads per page — bounds memory for a long history instead of loading the
/// whole result set at once (HU-01: "se escribe por streaming... nunca
/// materializando todas las transacciones en memoria").
const int exportPageSize = 500;

/// Read-only Drift queries for HU-01/HU-02 (`ExportRepositoryImpl`).
@lazySingleton
class ExportLocalDatasource {
  const ExportLocalDatasource(this._db);

  final AppDatabase _db;

  Future<int> countTransactions({
    required TransactionExportFilter filter,
    required bool allHistory,
  }) async {
    final count = _db.transactions.id.count();
    final query = _db.selectOnly(_db.transactions)
      ..addColumns([count])
      ..where(_whereClause(filter, allHistory));
    return query.map((row) => row.read(count) ?? 0).getSingle();
  }

  Future<List<Transaction>> getTransactionsPage({
    required TransactionExportFilter filter,
    required bool allHistory,
    required int offset,
  }) =>
      (_db.select(_db.transactions)
            ..where((_) => _whereClause(filter, allHistory))
            ..orderBy([(t) => OrderingTerm.asc(t.date)])
            ..limit(exportPageSize, offset: offset))
          .get();

  /// Archived accounts are included on purpose (HU-01/02: "el archivo es
  /// historial, no vista activa"); only tombstoned ones are excluded.
  Future<List<Account>> getAllAccountsForExport() =>
      (_db.select(_db.accounts)..where((a) => a.tombstonedAt.isNull())).get();

  Future<List<Category>> getAllCategoriesForExport() =>
      (_db.select(_db.categories)
            ..where((c) => c.deletedAt.isNull() & c.tombstonedAt.isNull()))
          .get();

  /// Tag names for each of [transactionIds] (HU-01's `etiquetas` column),
  /// grouped in Dart from a single joined query rather than one query per row.
  Future<Map<String, List<String>>> getTagNamesByTransactionId(
    Set<String> transactionIds,
  ) async {
    if (transactionIds.isEmpty) {
      return const {};
    }
    final query = _db.select(_db.transactionTags).join([
      innerJoin(_db.tags, _db.tags.id.equalsExp(_db.transactionTags.tagId)),
    ])
      ..where(
        _db.transactionTags.transactionId.isIn(transactionIds) &
            _db.transactionTags.deletedAt.isNull() &
            _db.tags.deletedAt.isNull() &
            _db.tags.tombstonedAt.isNull(),
      );
    final rows = await query.get();
    final result = <String, List<String>>{};
    for (final row in rows) {
      final link = row.readTable(_db.transactionTags);
      final tag = row.readTable(_db.tags);
      result.putIfAbsent(link.transactionId, () => []).add(tag.name);
    }
    return result;
  }

  Expression<bool> _whereClause(
    TransactionExportFilter filter,
    bool allHistory,
  ) {
    Expression<bool> clause = _db.transactions.deletedAt.isNull() &
        _db.transactions.tombstonedAt.isNull();

    if (filter.accountIds.isNotEmpty) {
      clause = clause &
          (_db.transactions.accountId.isIn(filter.accountIds) |
              _db.transactions.transferAccountId.isIn(filter.accountIds));
    }
    if (filter.categoryIds.isNotEmpty) {
      clause = clause & _db.transactions.categoryId.isIn(filter.categoryIds);
    }
    if (filter.types.isNotEmpty) {
      clause = clause &
          _db.transactions.type.isInValues(filter.types.map(_toDbType));
    }
    if (filter.searchText.trim().isNotEmpty) {
      clause = clause &
          _db.transactions.note.like('%${filter.searchText.trim()}%');
    }
    if (!allHistory) {
      if (filter.startDate != null) {
        clause = clause & _db.transactions.date.isBiggerOrEqualValue(filter.startDate!);
      }
      if (filter.endDate != null) {
        clause = clause & _db.transactions.date.isSmallerOrEqualValue(filter.endDate!);
      }
    }
    if (filter.tagIds.isNotEmpty) {
      final matchingIds = _db.selectOnly(_db.transactionTags)
        ..addColumns([_db.transactionTags.transactionId])
        ..where(
          _db.transactionTags.tagId.isIn(filter.tagIds) &
              _db.transactionTags.deletedAt.isNull(),
        );
      clause = clause &
          _db.transactions.id.isInQuery(matchingIds);
    }

    return clause;
  }

  EntryType _toDbType(ImportEntryType type) => switch (type) {
        ImportEntryType.income => EntryType.income,
        ImportEntryType.expense => EntryType.expense,
        ImportEntryType.transfer => EntryType.transfer,
      };
}
