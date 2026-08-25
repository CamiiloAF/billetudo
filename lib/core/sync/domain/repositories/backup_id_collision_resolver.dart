import '../../../error/result.dart';

/// Detects, in a single roundtrip, which ids of a decoded `.billetudo.json`
/// backup already exist in Postgres under a **different** `user_id` than the
/// one restoring it — the "same id, different account" collision a restore
/// across two Supabase accounts on the same device can produce.
///
/// Analogous to `DataOwnershipClaimer` (`core/sync/data/datasources/
/// data_ownership_claimer.dart`): exposed here, in `domain`, so
/// `import_export` depends on this abstraction instead of importing
/// `auth/data` or `core/sync/data` directly. Implemented in
/// `features/auth/data/datasources/local_data_ownership_datasource.dart`,
/// the same natural home as the seed-category ownership check it already
/// does for HU-04 — both are "does the signed-in account already have a row
/// with this id" checks against Postgres.
abstract class BackupIdCollisionResolver {
  /// [idsByTable] maps a backup table name (ej. `'transactions'`, the same
  /// camelCase keys `BackupJsonDatasource.backupTableNames` uses) to the ids
  /// present in that table in the backup. Returns the subset, per table, of
  /// those ids that already exist in Postgres owned by a user other than
  /// [userId] — never the colliding row's data itself, and never the other
  /// account's `user_id` (see the guarding SQL function, `supabase/
  /// migrations/20260825000000_check_backup_restore_id_collisions.sql`).
  ///
  /// `Left(NetworkFailure)` on any failure reaching Postgres — fail-closed,
  /// same contract as `DataOwnershipClaimer.claimUnownedRows`: the caller
  /// must abort the restore rather than guess whether a collision exists.
  FutureResult<Map<String, List<String>>> findCollidingIds({
    required String userId,
    required Map<String, List<String>> idsByTable,
  });
}
