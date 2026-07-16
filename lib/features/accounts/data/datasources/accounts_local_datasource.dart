import 'package:drift/drift.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/database/app_database.dart';

/// An account row together with the (non-deleted) transaction rows that move
/// it, on either side of a transfer. Data-layer type: it never leaves `data/`.
class AccountWithMovementRows {
  const AccountWithMovementRows({
    required this.account,
    required this.movements,
  });

  final Account account;
  final List<Transaction> movements;
}

/// Drift queries for the Accounts feature.
///
/// A plain injected class instead of a `@DriftAccessor`: the feature needs no
/// new tables or generated code, so it does not touch `app_database.dart` nor
/// force a schema regeneration.
///
/// It deliberately returns **raw movement rows** rather than a SQL `SUM`: the
/// balance rule (which sign each movement carries, and that soft-deleted rows
/// never count) belongs to the domain and must have a single implementation.
/// SQL only narrows which rows are read.
///
/// Two deletion columns are in play here and they are NOT interchangeable:
///  - `Accounts.tombstonedAt`: the account's own logical delete (HU-08), a
///    referential-integrity tombstone. Every account filter below uses this.
///  - `Transactions.deletedAt` / `Goals.deletedAt`: those rows' UX trash. A
///    trashed movement must not count towards a balance nor a deletion impact.
///
/// Account filters do NOT test `Accounts.deletedAt`: Accounts has no trash flow,
/// so nothing ever stamps it. If one is ever added, the read/list queries must
/// start excluding trashed accounts, but [updateAccount] must NOT — an un-delete
/// has to be able to write to the very row it is restoring.
@lazySingleton
class AccountsLocalDatasource {
  const AccountsLocalDatasource(this._db);

  final AppDatabase _db;

  Stream<List<AccountWithMovementRows>> watchAccounts({
    required bool archived,
  }) =>
      _watchJoined(
        (accounts) => accounts.archived.equals(archived),
      );

  Stream<List<AccountWithMovementRows>> watchAccount(String id) =>
      _watchJoined((accounts) => accounts.id.equals(id));

  Future<Account?> getAccount(String id) => (_db.select(_db.accounts)
        ..where((a) => a.id.equals(id) & a.tombstonedAt.isNull()))
      .getSingleOrNull();

  Future<Account> insertAccount(AccountsCompanion companion) =>
      _db.into(_db.accounts).insertReturning(companion);

  /// Every repository write funnels through here, so the `tombstonedAt IS NULL`
  /// guard lives here too: a deleted account must not be resurrected, mutated
  /// nor re-stamped with a fresh `tombstonedAt`. No match returns `null`, which
  /// the repository already turns into a `NotFoundFailure`.
  Future<Account?> updateAccount(String id, AccountsCompanion companion) =>
      (_db.update(_db.accounts)
            ..where((a) => a.id.equals(id) & a.tombstonedAt.isNull()))
          .writeReturning(companion)
          .then((rows) => rows.isEmpty ? null : rows.first);

  /// Removes the row for real, unlike the `tombstonedAt` tombstone of HU-08.
  ///
  /// Only legitimate to roll back a creation that could not be completed: that
  /// row is seconds old, nothing references it and the user never saw it, so
  /// there is no history to protect and no tombstone worth syncing.
  Future<void> hardDeleteAccount(String id) =>
      (_db.delete(_db.accounts)..where((a) => a.id.equals(id))).go();

  /// Next `sortOrder`: last place among the accounts that still exist.
  Future<int> nextSortOrder() async {
    final maxOrder = _db.accounts.sortOrder.max();
    final query = _db.selectOnly(_db.accounts)
      ..addColumns([maxOrder])
      ..where(_db.accounts.tombstonedAt.isNull());
    final row = await query.getSingleOrNull();
    final current = row?.read(maxOrder);
    return current == null ? 0 : current + 1;
  }

  /// HU-09: rewrites `sortOrder` as a contiguous 0..n-1 sequence, in one
  /// transaction so the list never reads a half-applied order. Deleted rows are
  /// skipped by the same guard as [updateAccount]; today the ids always come
  /// from an already-filtered list, so this only holds under a race.
  Future<void> reorderAccounts(List<String> orderedIds, DateTime now) =>
      _db.transaction(() async {
        for (var index = 0; index < orderedIds.length; index++) {
          await (_db.update(_db.accounts)
                ..where(
                  (a) =>
                      a.id.equals(orderedIds[index]) & a.tombstonedAt.isNull(),
                ))
              .write(
            AccountsCompanion(sortOrder: Value(index), updatedAt: Value(now)),
          );
        }
      });

  Future<int> countTransactions(String accountId) {
    final count = _db.transactions.id.count();
    final query = _db.selectOnly(_db.transactions)
      ..addColumns([count])
      ..where(_movesAccount(accountId) & _db.transactions.deletedAt.isNull());
    return query.map((row) => row.read(count) ?? 0).getSingle();
  }

  /// Distinct debts touched by the account's active transactions. `Debts` has
  /// no `accountId`, so the link is `Transactions.debtId`.
  Future<int> countLinkedDebts(String accountId) {
    final count = _db.transactions.debtId.count(distinct: true);
    final query = _db.selectOnly(_db.transactions)
      ..addColumns([count])
      ..where(
        _movesAccount(accountId) &
            _db.transactions.deletedAt.isNull() &
            _db.transactions.debtId.isNotNull(),
      );
    return query.map((row) => row.read(count) ?? 0).getSingle();
  }

  Future<int> countLinkedGoals(String accountId) {
    final count = _db.goals.id.count();
    final query = _db.selectOnly(_db.goals)
      ..addColumns([count])
      ..where(
        _db.goals.accountId.equals(accountId) & _db.goals.deletedAt.isNull(),
      );
    return query.map((row) => row.read(count) ?? 0).getSingle();
  }

  /// Active accounts other than [accountId]: drives the "last account" block.
  Future<int> countOtherActiveAccounts(String accountId) {
    final count = _db.accounts.id.count();
    final query = _db.selectOnly(_db.accounts)
      ..addColumns([count])
      ..where(
        _db.accounts.id.equals(accountId).not() &
            _db.accounts.tombstonedAt.isNull() &
            _db.accounts.archived.equals(false),
      );
    return query.map((row) => row.read(count) ?? 0).getSingle();
  }

  Expression<bool> _movesAccount(String accountId) =>
      _db.transactions.accountId.equals(accountId) |
      _db.transactions.transferAccountId.equals(accountId);

  Stream<List<AccountWithMovementRows>> _watchJoined(
    Expression<bool> Function($AccountsTable accounts) filter,
  ) {
    final query = _db.select(_db.accounts).join([
      leftOuterJoin(
        _db.transactions,
        (_db.transactions.accountId.equalsExp(_db.accounts.id) |
                _db.transactions.transferAccountId.equalsExp(_db.accounts.id)) &
            // Kept in the ON clause, not in WHERE: a WHERE would turn the outer
            // join into an inner one and hide accounts with no movements.
            _db.transactions.deletedAt.isNull(),
      ),
    ])
      ..where(_db.accounts.tombstonedAt.isNull() & filter(_db.accounts))
      ..orderBy([
        OrderingTerm.asc(_db.accounts.sortOrder),
        OrderingTerm.asc(_db.accounts.createdAt),
      ]);

    return query.watch().map(_groupByAccount);
  }

  List<AccountWithMovementRows> _groupByAccount(List<TypedResult> rows) {
    // Insertion order == the ORDER BY, since each account's rows are
    // contiguous.
    final accounts = <String, Account>{};
    final movements = <String, List<Transaction>>{};

    for (final row in rows) {
      final account = row.readTable(_db.accounts);
      accounts[account.id] = account;
      final movementList = movements.putIfAbsent(account.id, () => []);
      final movement = row.readTableOrNull(_db.transactions);
      if (movement != null) {
        movementList.add(movement);
      }
    }

    return [
      for (final entry in accounts.entries)
        AccountWithMovementRows(
          account: entry.value,
          movements: movements[entry.key] ?? const [],
        ),
    ];
  }
}
