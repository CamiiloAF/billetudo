import 'package:injectable/injectable.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Thrown by [BackupIdCollisionDatasource.findCollidingIds] on any failure
/// reaching Postgres — same shape as `SeedCategoryOwnershipCheckException`
/// (`features/auth/data/datasources/seed_category_ownership_remote_datasource.dart`).
class BackupIdCollisionCheckException implements Exception {
  const BackupIdCollisionCheckException(this.cause);

  final Object cause;

  @override
  String toString() => 'BackupIdCollisionCheckException($cause)';
}

/// One backup row identifier to check for a collision: [tableName] is the
/// camelCase key used throughout `import_export`'s backup JSON (ej.
/// `'goalContributions'`), converted to the real snake_case Postgres table
/// name before the RPC call — the allowlist inside the SQL function
/// (`supabase/migrations/20260825000000_check_backup_restore_id_collisions.sql`)
/// validates against those snake_case names, never an interpolated string.
class BackupRowId {
  const BackupRowId({required this.tableName, required this.id});

  final String tableName;
  final String id;
}

/// Wraps the single-roundtrip RPC that backs restoring a `.billetudo.json`
/// backup under a Supabase account different from the one that originally
/// synced some of its ids (`BackupIdCollisionResolver`, `core/sync/domain/
/// repositories/backup_id_collision_resolver.dart`).
///
/// Lives next to `data_ownership_claimer.dart` on purpose: both are the
/// core-level plumbing a feature-level datasource (here, `features/auth/
/// data/datasources/local_data_ownership_datasource.dart`) delegates to
/// rather than talking to Postgres directly.
@lazySingleton
class BackupIdCollisionDatasource {
  const BackupIdCollisionDatasource(this._supabase);

  final SupabaseClient _supabase;

  static const _rpcName = 'check_backup_restore_id_collisions';

  /// Returns the subset of [rows] whose `(table_name, id)` already exists in
  /// Postgres owned by a user other than [userId], grouped back by table
  /// name (the same camelCase keys [rows] came in with). Never returns the
  /// colliding row's data or the other account's `user_id` — the SQL
  /// function only ever emits `(table_name, id)` pairs.
  Future<Map<String, List<String>>> findCollidingIds(
    String userId,
    List<BackupRowId> rows,
  ) async {
    if (rows.isEmpty) {
      return const {};
    }
    try {
      final response = await _supabase.rpc<List<dynamic>>(
        _rpcName,
        params: {
          'p_user_id': userId,
          'p_rows': [
            for (final row in rows)
              {'table_name': _sqlNameOf(row.tableName), 'id': row.id},
          ],
        },
      );
      final sqlNameToCamelCase = {
        for (final row in rows) _sqlNameOf(row.tableName): row.tableName,
      };
      final result = <String, List<String>>{};
      for (final raw in response) {
        final entry = raw as Map<String, dynamic>;
        final sqlName = entry['table_name'] as String;
        final id = entry['id'] as String;
        final camelCase = sqlNameToCamelCase[sqlName] ?? sqlName;
        result.putIfAbsent(camelCase, () => []).add(id);
      }
      return result;
    } on PostgrestException catch (e) {
      throw BackupIdCollisionCheckException(e);
    } catch (e) {
      throw BackupIdCollisionCheckException(e);
    }
  }

  /// snake_case SQL table name from the camelCase key used in the backup
  /// JSON — the same conversion `BackupJsonDatasource._sqlNameOf` does,
  /// duplicated here (both are a 3-line pure function) rather than exporting
  /// a private helper across features.
  String _sqlNameOf(String camelCase) => camelCase.replaceAllMapped(
        RegExp('[A-Z]'),
        (m) => '_${m.group(0)!.toLowerCase()}',
      );
}
