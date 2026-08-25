import 'package:drift/drift.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/database/app_database.dart';
import '../../../../core/error/result.dart';
import '../../../../core/sync/data/datasources/backup_id_collision_datasource.dart';
import '../../../../core/sync/data/datasources/data_ownership_claimer.dart';
import '../../../../core/sync/data/datasources/synced_tables.dart';
import '../../../../core/sync/domain/repositories/backup_id_collision_resolver.dart';
import 'seed_category_ownership_remote_datasource.dart';

/// Prefix of a seed category's id (e.g. `seed-food-drink`), assigned by the
/// `category_seeds` catalog (`docs/requirements/fase-1/05-auth-sync.md`, decision
/// #12) — the one thing that tells this datasource "this row might already
/// exist under this account, check before claiming it".
const _seedIdPrefix = 'seed-';

/// HU-04's "claim" step: stamps `user_id` on every row still owned by nobody
/// (created on this device before the user ever signed in) with the account
/// that just authenticated.
///
/// Once `user_id` is set, PowerSync's write interception (decision #6,
/// docs/requirements/fase-1/05-auth-sync.md) treats each row as changed and queues it
/// for upload — this UPDATE is what actually associates local data with the
/// account; there is no separate "upload" call to make.
///
/// Raw `customStatement` across every owned table, mirroring the loop already used
/// for the `updatedAt` seconds->millis migration in `AppDatabase` (v4 -> v5):
/// the statement shape is identical for every table, so a typed Drift
/// `update(table).write(...)` per table would just repeat the same thing 12
/// times with no extra safety.
///
/// `categories` is the one exception, in two ways. First: before claiming,
/// every local `seed-*` category with no owner yet is checked against
/// Postgres (decision #12). If the signed-in account already has a row with
/// that same id — it seeded this catalog on another device before — this
/// device's copy is **not** claimed; it is left `user_id IS NULL` forever
/// (harmless: HU-04's summary already counted it, and PowerSync's next
/// download simply overwrites the same id with the account's canonical row
/// once it lands locally). Second: unlike every other table, `categories`
/// is claimed one row at a time in parent-before-child order (see
/// `_claimCategoriesTopologically`) rather than a single mass `UPDATE` —
/// Postgres' FK `(parent_id, user_id) references categories (id, user_id)`
/// rejects a child claimed (and thus uploaded) before its parent.
// Registered as itself (`@lazySingleton`, not `@LazySingleton(as: ...)`):
// this datasource implements *two* domain interfaces
// (`DataOwnershipClaimer` and `BackupIdCollisionResolver`), and injectable's
// `as:` binds only one abstract type per annotation. `RegisterModule`
// (`core/di/register_module.dart`) exposes both bindings from this same
// singleton instance instead.
@lazySingleton
class LocalDataOwnershipDatasource
    implements DataOwnershipClaimer, BackupIdCollisionResolver {
  const LocalDataOwnershipDatasource(
    this._db,
    this._seedOwnership,
    this._collisionDatasource,
  );

  final AppDatabase _db;
  final SeedCategoryOwnershipRemoteDatasource _seedOwnership;
  final BackupIdCollisionDatasource _collisionDatasource;

  /// [BackupIdCollisionResolver]'s "same id, different account" check for a
  /// `.billetudo.json` restore — a separate concern from [claimUnownedRows]
  /// (HU-04's post-login merge of never-synced local rows), but implemented
  /// on this same datasource for the same reason the seed-category ownership
  /// check is: this is the class that already knows how to ask Postgres
  /// "does the signed-in account already have a row with this id" without
  /// import_export depending on `auth/data` or `core/sync/data` directly.
  @override
  FutureResult<Map<String, List<String>>> findCollidingIds({
    required String userId,
    required Map<String, List<String>> idsByTable,
  }) async {
    final rows = [
      for (final entry in idsByTable.entries)
        for (final id in entry.value)
          BackupRowId(tableName: entry.key, id: id),
    ];
    if (rows.isEmpty) {
      return const Right({});
    }
    try {
      final result =
          await _collisionDatasource.findCollidingIds(userId, rows);
      return Right(result);
    } on BackupIdCollisionCheckException catch (e, stackTrace) {
      return Left(
        NetworkFailure(
          'failed to check backup id collisions against Postgres',
          cause: e.cause,
          stackTrace: stackTrace,
        ),
      );
    }
  }

  @override
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
      for (final table in ownedTables) {
        if (table == 'categories') {
          await _claimCategoriesTopologically(
            userId,
            updatedAt,
            excludedSeedIds,
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

  /// Claims `categories` row by row, parent before child, instead of the
  /// single mass `UPDATE` every other table gets in [claimUnownedRows].
  ///
  /// Postgres enforces `foreign key (parent_id, user_id) references
  /// categories (id, user_id)` (`supabase/migrations/20260701000000_baseline.sql`).
  /// A mass `UPDATE ... WHERE user_id IS NULL` stamps rows in whatever order
  /// SQLite happens to scan the table, not parent-before-child — if a child's
  /// `UPDATE` reaches PowerSync's upload queue before its parent's, Postgres
  /// rejects it with `23503` because `(parent_id, user_id)` does not exist
  /// yet. Claiming one row at a time in topological order makes each
  /// individual `UPDATE` enter that queue in a safe sequence.
  ///
  /// Reuses the same Kahn's-algorithm-style ordering as
  /// `BackupJsonDatasource._parentsBeforeChildren` (a row is "ready" once its
  /// `parentId` is null, already claimed, or not part of this claim batch at
  /// all — ej. a parent that already has an owner).
  Future<void> _claimCategoriesTopologically(
    String userId,
    int updatedAt,
    List<String> excludedSeedIds,
  ) async {
    final unowned = await (_db.select(_db.categories)
          ..where((c) => c.userId.isNull()))
        .get();
    final excluded = excludedSeedIds.toSet();
    final claimable = [
      for (final row in unowned)
        if (!excluded.contains(row.id)) row,
    ];
    if (claimable.isEmpty) {
      return;
    }

    final claimableIds = {for (final row in claimable) row.id};
    final claimed = <String>{};
    var remaining = claimable;

    while (remaining.isNotEmpty) {
      final ready = <Category>[];
      final stillWaiting = <Category>[];
      for (final row in remaining) {
        final parentId = row.parentId;
        final isReady = parentId == null ||
            claimed.contains(parentId) ||
            !claimableIds.contains(parentId);
        if (isReady) {
          ready.add(row);
        } else {
          stillWaiting.add(row);
        }
      }

      if (ready.isEmpty) {
        // Cycle within this batch: nothing more can become ready (already
        // corrupt data, out of scope here). Claim the rest in their
        // remaining order rather than looping forever.
        ready.addAll(stillWaiting);
        stillWaiting.clear();
      }

      for (final row in ready) {
        await _db.customStatement(
          'UPDATE categories SET user_id = ?, updated_at = ? WHERE id = ?',
          [userId, updatedAt, row.id],
        );
        claimed.add(row.id);
      }
      remaining = stillWaiting;
    }
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
