import 'package:drift/drift.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/database/app_database.dart';

/// A transaction row together with the (non-tombstoned) account/category/tag
/// rows a list item or the detail screen needs to render. Data-layer type: it
/// never leaves `data/`.
class TransactionRowWithJoins {
  const TransactionRowWithJoins({
    required this.transaction,
    required this.account,
    this.transferAccount,
    this.category,
    this.tags = const <Tag>[],
  });

  final Transaction transaction;
  final Account account;
  final Account? transferAccount;
  final Category? category;
  final List<Tag> tags;
}

/// How the transaction list is ordered at the SQL level (HU-06).
enum TransactionOrderBy { dateDesc, amountDesc }

/// Drift queries for the Transactions feature.
///
/// A plain injected class instead of a `@DriftAccessor`, same reasoning as
/// `AccountsLocalDatasource`: no new tables, no forced schema regeneration.
///
/// [watchTransactions] joins Accounts (both sides), Categories and
/// Tags/TransactionTags in a single reactive query, so the stream re-emits on
/// a change to *any* of them (e.g. a tag rename, or a new tag assignment) —
/// not just on a change to `Transactions` itself. The tag join necessarily
/// fans a transaction out into one row per tag (or one row with a null tag
/// when it has none); [_groupByTransaction] folds that back into one
/// [TransactionRowWithJoins] per transaction, same pattern as
/// `AccountsLocalDatasource._groupByAccount`.
@lazySingleton
class TransactionsLocalDatasource {
  const TransactionsLocalDatasource(this._db);

  final AppDatabase _db;

  Expression<bool> get _alive =>
      _db.transactions.deletedAt.isNull() &
      _db.transactions.tombstonedAt.isNull();

  Stream<List<TransactionRowWithJoins>> watchTransactions({
    Set<String> accountIds = const <String>{},
    Set<String> categoryIds = const <String>{},
    Set<EntryType> types = const <EntryType>{},
    Set<String> tagIds = const <String>{},
    String searchText = '',
    required DateTime periodStart,
    required DateTime periodEndExclusive,
    TransactionOrderBy orderBy = TransactionOrderBy.dateDesc,
  }) {
    final transferAccounts = _db.alias(_db.accounts, 'transfer_accounts');

    final query = _db.select(_db.transactions).join([
      innerJoin(
        _db.accounts,
        _db.accounts.id.equalsExp(_db.transactions.accountId),
      ),
      leftOuterJoin(
        transferAccounts,
        transferAccounts.id.equalsExp(_db.transactions.transferAccountId),
      ),
      leftOuterJoin(
        _db.categories,
        _db.categories.id.equalsExp(_db.transactions.categoryId),
      ),
      leftOuterJoin(
        _db.transactionTags,
        _db.transactionTags.transactionId.equalsExp(_db.transactions.id) &
            _db.transactionTags.deletedAt.isNull() &
            _db.transactionTags.tombstonedAt.isNull(),
      ),
      leftOuterJoin(
        _db.tags,
        _db.tags.id.equalsExp(_db.transactionTags.tagId),
      ),
    ])
      ..where(
        _alive &
            _db.transactions.date.isBiggerOrEqualValue(periodStart) &
            _db.transactions.date.isSmallerThanValue(periodEndExclusive) &
            _matchesAny(
              accountIds,
              () =>
                  _db.transactions.accountId.isIn(accountIds) |
                  _db.transactions.transferAccountId.isIn(accountIds),
            ) &
            _matchesAny(
              categoryIds,
              () => _db.transactions.categoryId.isIn(categoryIds),
            ) &
            _matchesAny(
              types,
              () => _db.transactions.type.isInValues(types),
            ) &
            _matchesAny(
              tagIds,
              () =>
                  _db.transactions.id.isInQuery(_taggedTransactionIds(tagIds)),
            ) &
            (searchText.trim().isEmpty
                ? const Constant(true)
                : (_db.transactions.note.contains(searchText.trim()) |
                    _db.categories.name.contains(searchText.trim()))),
      )
      ..orderBy([
        switch (orderBy) {
          TransactionOrderBy.dateDesc =>
            OrderingTerm.desc(_db.transactions.date),
          TransactionOrderBy.amountDesc =>
            OrderingTerm.desc(_db.transactions.amountMinor),
        },
        // Stable tiebreaker: also keeps every fanned-out tag row of the same
        // transaction contiguous, which [_groupByTransaction] relies on.
        OrderingTerm.asc(_db.transactions.id),
      ]);

    return query.watch().map(_groupByTransaction);
  }

  /// HU-08: the same join as [watchTransactions], narrowed to one id.
  Stream<List<TransactionRowWithJoins>> watchTransactionDetail(String id) {
    final transferAccounts = _db.alias(_db.accounts, 'transfer_accounts');

    final query = _db.select(_db.transactions).join([
      innerJoin(
        _db.accounts,
        _db.accounts.id.equalsExp(_db.transactions.accountId),
      ),
      leftOuterJoin(
        transferAccounts,
        transferAccounts.id.equalsExp(_db.transactions.transferAccountId),
      ),
      leftOuterJoin(
        _db.categories,
        _db.categories.id.equalsExp(_db.transactions.categoryId),
      ),
      leftOuterJoin(
        _db.transactionTags,
        _db.transactionTags.transactionId.equalsExp(_db.transactions.id) &
            _db.transactionTags.deletedAt.isNull() &
            _db.transactionTags.tombstonedAt.isNull(),
      ),
      leftOuterJoin(
        _db.tags,
        _db.tags.id.equalsExp(_db.transactionTags.tagId),
      ),
    ])
      ..where(_db.transactions.id.equals(id) & _alive);

    return query.watch().map(_groupByTransaction);
  }

  Future<Transaction?> getTransaction(String id) =>
      (_db.select(_db.transactions)..where((t) => t.id.equals(id) & _alive))
          .getSingleOrNull();

  Future<Transaction> insertTransaction(TransactionsCompanion companion) =>
      _db.into(_db.transactions).insertReturning(companion);

  /// Every normal edit and the soft-delete funnel through here, so the
  /// "alive" guard lives here too: a trashed transaction must not be silently
  /// mutated by anything other than [restoreTransaction]. No match returns
  /// `null`, which the repository turns into a `NotFoundFailure`.
  Future<Transaction?> updateTransaction(
    String id,
    TransactionsCompanion companion,
  ) =>
      (_db.update(_db.transactions)..where((t) => t.id.equals(id) & _alive))
          .writeReturning(companion)
          .then((rows) => rows.isEmpty ? null : rows.first);

  /// HU-05: undo from the trash. Only guards `tombstonedAt IS NULL`, on
  /// purpose: the row being restored is, by definition, currently
  /// `deletedAt IS NOT NULL`.
  Future<Transaction?> restoreTransaction(
    String id,
    TransactionsCompanion companion,
  ) =>
      (_db.update(_db.transactions)
            ..where((t) => t.id.equals(id) & t.tombstonedAt.isNull()))
          .writeReturning(companion)
          .then((rows) => rows.isEmpty ? null : rows.first);

  /// `true` (no-op filter) when [values] is empty — every `Set` filter is
  /// inclusive-empty (HU-06a/06): "match everything", not "match nothing".
  Expression<bool> _matchesAny(
    Iterable<Object?> values,
    Expression<bool> Function() build,
  ) =>
      values.isEmpty ? const Constant(true) : build();

  /// A single-column subquery for `isInQuery`: it must stay a raw
  /// [BaseSelectStatement] (not `.map()`-ped) for Drift to embed it as SQL.
  BaseSelectStatement<TypedResult> _taggedTransactionIds(Set<String> tagIds) =>
      _db.selectOnly(_db.transactionTags)
        ..addColumns([_db.transactionTags.transactionId])
        ..where(
          _db.transactionTags.tagId.isIn(tagIds) &
              _db.transactionTags.deletedAt.isNull() &
              _db.transactionTags.tombstonedAt.isNull(),
        );

  List<TransactionRowWithJoins> _groupByTransaction(List<TypedResult> rows) {
    final transferAccounts = _db.alias(_db.accounts, 'transfer_accounts');

    // Insertion order == the ORDER BY, since each transaction's fanned-out
    // tag rows are contiguous.
    final byId = <String, TransactionRowWithJoins>{};

    for (final row in rows) {
      final transaction = row.readTable(_db.transactions);
      final tag = row.readTableOrNull(_db.tags);

      final existing = byId[transaction.id];
      if (existing == null) {
        byId[transaction.id] = TransactionRowWithJoins(
          transaction: transaction,
          account: row.readTable(_db.accounts),
          transferAccount: row.readTableOrNull(transferAccounts),
          category: row.readTableOrNull(_db.categories),
          tags: tag == null ? const [] : [tag],
        );
      } else if (tag != null) {
        byId[transaction.id] = TransactionRowWithJoins(
          transaction: existing.transaction,
          account: existing.account,
          transferAccount: existing.transferAccount,
          category: existing.category,
          tags: [...existing.tags, tag],
        );
      }
    }

    return byId.values.toList();
  }
}
