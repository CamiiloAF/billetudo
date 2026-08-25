import 'package:drift/drift.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/database/app_database.dart';
import '../../../../core/sync/data/datasources/synced_tables.dart';

/// Detects, right after a Google/Apple sign-in exchanges a Supabase session,
/// whether this device already holds local data owned by a **different**
/// account — the exact inverse of HU-04's claim check
/// (`LocalDataOwnershipDatasource`, `user_id IS NULL`).
///
/// A device that was signed into account A, then signed out (HU-06) keeping
/// its data, then signs in as account B on the same device, must not silently
/// merge B's login into A's local rows — that would either corrupt A's data
/// (rows re-owned to B) or upload it under the wrong account. The caller
/// (`AuthRepositoryImpl`) uses this to block the sign-in behind a
/// confirmation sheet instead.
///
/// Raw `customSelect` across every owned table, mirroring the loop shape
/// already used by `LocalDataOwnershipDatasource.claimUnownedRows` — same
/// table list (`synced_tables.dart`), opposite predicate.
@lazySingleton
class LocalDataConflictDatasource {
  const LocalDataConflictDatasource(this._db);

  final AppDatabase _db;

  /// True as soon as any owned table has a row whose `user_id` is set to
  /// something other than [incomingUserId] — including `NULL` never counting
  /// as a conflict (that is HU-04's territory, not this one).
  ///
  /// Any exception reading Drift (e.g. a corrupt PowerSync view) is left to
  /// propagate uncaught: the caller must fail-closed, treating a detection
  /// failure exactly like a real conflict, never as "no conflict found".
  Future<bool> hasConflict(String incomingUserId) async {
    for (final table in ownedTables) {
      final rows = await _db.customSelect(
        'SELECT 1 FROM $table WHERE user_id IS NOT NULL AND user_id != ? '
        'LIMIT 1',
        variables: [Variable.withString(incomingUserId)],
      ).get();
      if (rows.isNotEmpty) {
        return true;
      }
    }
    return false;
  }
}
