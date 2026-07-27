import 'package:drift/drift.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/database/app_database.dart';
import '../../../../core/error/result.dart';
import 'seed_category_ownership_remote_datasource.dart';

/// Every table with `_SyncColumns.userId` (see `app_database.dart`) — the same
/// tables mirrored in `core/database/powersync_schema.dart`.
const _ownedTables = [
  'accounts',
  'categories',
  'transactions',
  'budgets',
  'goals',
  'debts',
  'scheduled_payments',
  'tags',
  'transaction_tags',
  'budget_accounts',
  'budget_categories',
  'budget_period_overrides',
  'app_settings',
];

/// Prefix of a seed category's id (e.g. `seed-food-drink`), assigned by the
/// `category_seeds` catalog (`docs/requirements/05-auth-sync.md`, decision
/// #12) — the one thing that tells this datasource "this row might already
/// exist under this account, check before claiming it".
const _seedIdPrefix = 'seed-';

/// HU-04's "claim" step: stamps `user_id` on every row still owned by nobody
/// (created on this device before the user ever signed in) with the account
/// that just authenticated.
///
/// Once `user_id` is set, PowerSync's write interception (decision #6,
/// docs/requirements/05-auth-sync.md) treats each row as changed and queues it
/// for upload — this UPDATE is what actually associates local data with the
/// account; there is no separate "upload" call to make.
///
/// Raw `customStatement` across every owned table, mirroring the loop already used
/// for the `updatedAt` seconds->millis migration in `AppDatabase` (v4 -> v5):
/// the statement shape is identical for every table, so a typed Drift
/// `update(table).write(...)` per table would just repeat the same thing 12
/// times with no extra safety.
///
/// `categories` is the one exception: before claiming, every local `seed-*`
/// category with no owner yet is checked against Postgres (decision #12). If
/// the signed-in account already has a row with that same id — it seeded
/// this catalog on another device before — this device's copy is **not**
/// claimed; it is left `user_id IS NULL` forever (harmless: HU-04's summary
/// already counted it, and PowerSync's next download simply overwrites the
/// same id with the account's canonical row once it lands locally).
@lazySingleton
class LocalDataOwnershipDatasource {
  const LocalDataOwnershipDatasource(this._db, this._seedOwnership);

  final AppDatabase _db;
  final SeedCategoryOwnershipRemoteDatasource _seedOwnership;

  FutureResult<Unit> claimUnownedRows(String userId) async {
    final alreadyOwnedSeedIds = await _alreadyOwnedSeedIds(userId);
    if (alreadyOwnedSeedIds case Left(value: final failure)) {
      return Left(failure);
    }
    final excludedSeedIds = alreadyOwnedSeedIds.getOrElse(
      (_) => throw StateError('unreachable: alreadyOwnedSeedIds is Left'),
    );

    await _db.transaction(() async {
      final updatedAt = DateTime.now().millisecondsSinceEpoch;
      for (final table in _ownedTables) {
        if (table == 'categories' && excludedSeedIds.isNotEmpty) {
          final placeholders =
              List.filled(excludedSeedIds.length, '?').join(', ');
          await _db.customStatement(
            'UPDATE categories SET user_id = ?, updated_at = ? '
            'WHERE user_id IS NULL AND id NOT IN ($placeholders)',
            [userId, updatedAt, ...excludedSeedIds],
          );
        } else {
          await _db.customStatement(
            'UPDATE $table SET user_id = ?, updated_at = ? '
            'WHERE user_id IS NULL',
            [userId, updatedAt],
          );
        }
      }
    });

    return const Right(unit);
  }

  /// Which of this device's unowned local `seed-*` categories the signed-in
  /// account already has a row for in Postgres — the set that must be
  /// excluded from claiming. `Left(NetworkFailure)` when the check itself
  /// can't reach Postgres: the merge aborts rather than guess (claiming a
  /// row the account already has would duplicate it; refusing to claim a row
  /// that's actually new would silently orphan it).
  Future<Result<List<String>>> _alreadyOwnedSeedIds(String userId) async {
    final localSeedRows = await (_db.select(_db.categories)
          ..where(
            (c) => c.userId.isNull() & c.id.like('$_seedIdPrefix%'),
          ))
        .get();
    final localSeedIds = localSeedRows.map((row) => row.id).toList();
    if (localSeedIds.isEmpty) {
      return const Right([]);
    }

    try {
      final existing = await _seedOwnership.existingSeedCategoryIds(
        userId,
        localSeedIds,
      );
      return Right(existing);
    } on SeedCategoryOwnershipCheckException catch (e, stackTrace) {
      return Left(
        NetworkFailure(
          'failed to check which seed categories the account already owns',
          cause: e.cause,
          stackTrace: stackTrace,
        ),
      );
    }
  }
}
