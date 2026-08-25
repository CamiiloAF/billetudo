import 'package:injectable/injectable.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/error/result.dart';
import '../../../../core/sync/domain/repositories/backup_id_collision_resolver.dart';
import '../entities/backup_fk_column_map.dart';

const _uuid = Uuid();

/// Table whose own `id` is never a source of a remap: `AppSettings.id`
/// defaults to the literal `'app'` (`core/database/app_database.dart`) — a
/// fixed singleton key every account legitimately shares, not the "same id,
/// different account" collision this use case exists to fix. It can still be
/// the *value* of a FK column elsewhere (it isn't, today — see
/// `backup_fk_column_map.dart`), so this only excludes it from the id
/// collision check, never from FK rewriting.
const _tableExcludedFromIdCollisionCheck = 'appSettings';

/// Restoring a `.billetudo.json` backup under a Supabase account different
/// from the one that originally synced some of its rows can collide: an id
/// generated on another device, under another account, that this account's
/// Postgres project also already has under a *different* `user_id`.
/// Inserting that row locally with its original id would, at the next
/// upload, try to `INSERT` a row Postgres already has for someone else —
/// RLS rejects it with `42501`, and worse, if it were ever allowed through,
/// it would silently misattribute someone else's data.
///
/// This use case, given the tables decoded from a backup and the id of the
/// account restoring it, asks [BackupIdCollisionResolver] which ids
/// actually collide, generates a brand new UUID for each one, and rewrites
/// every row so it — and everything that referenced it, across every table,
/// including the three FK columns Drift never declared `.references()` for
/// (`backup_fk_column_map.dart`) — uses the new id instead. Ids that do not
/// collide are left completely untouched, so a restore with no collision at
/// all produces byte-identical output to the input (HU-04's existing
/// behaviour, zero regression).
///
/// Must run before `BackupJsonDatasource._parentsBeforeChildren` and before
/// `restoreInsertOrder` is walked: both operate on ids, and a row's id (or
/// `parentId`) may have just been rewritten here.
@injectable
class ResolveBackupIdConflicts {
  const ResolveBackupIdConflicts(this._resolver);

  final BackupIdCollisionResolver _resolver;

  /// [tables] is the decoded backup's `"tables"` map: backup table name
  /// (camelCase, ej. `'goalContributions'`) to its list of row maps, exactly
  /// as `jsonDecode` produces it. Returns the same shape, with colliding
  /// rows' ids — and every FK column that pointed at one — replaced.
  FutureResult<Map<String, dynamic>> call({
    required String userId,
    required Map<String, dynamic> tables,
  }) async {
    final idsByTable = <String, List<String>>{
      for (final entry in tables.entries)
        if (entry.key != _tableExcludedFromIdCollisionCheck)
          entry.key: [
            for (final raw in entry.value as List<dynamic>)
              (raw as Map<String, dynamic>)['id'] as String,
          ],
    };
    if (idsByTable.values.every((ids) => ids.isEmpty)) {
      return Right(tables);
    }

    final collisionResult = await _resolver.findCollidingIds(
      userId: userId,
      idsByTable: idsByTable,
    );
    if (collisionResult case Left(value: final failure)) {
      return Left(failure);
    }
    final collidingIds = collisionResult.getOrElse(
      (_) => throw StateError('unreachable: collisionResult is Left'),
    );
    if (collidingIds.values.every((ids) => ids.isEmpty)) {
      return Right(tables);
    }

    // tableName -> (old id -> new id), built once for every table before any
    // row is rewritten, so a FK pointing at a row remapped later in this
    // same pass (ej. `categories.parentId` pointing at another remapped
    // category) still resolves correctly regardless of table order.
    final remapByTable = <String, Map<String, String>>{
      for (final entry in collidingIds.entries)
        if (entry.value.isNotEmpty)
          entry.key: {for (final id in entry.value) id: _uuid.v4()},
    };

    final rewritten = <String, dynamic>{
      for (final entry in tables.entries)
        entry.key: [
          for (final raw in entry.value as List<dynamic>)
            _rewriteRow(
              entry.key,
              raw as Map<String, dynamic>,
              remapByTable,
            ),
        ],
    };
    return Right(rewritten);
  }

  Map<String, dynamic> _rewriteRow(
    String tableName,
    Map<String, dynamic> row,
    Map<String, Map<String, String>> remapByTable,
  ) {
    final rewritten = Map<String, dynamic>.from(row);

    final ownIdRemap = remapByTable[tableName];
    final ownId = rewritten['id'] as String;
    final newOwnId = ownIdRemap?[ownId];
    if (newOwnId != null) {
      rewritten['id'] = newOwnId;
    }

    for (final fk
        in backupFkColumnsByTable[tableName] ?? const <BackupFkColumn>[]) {
      final value = rewritten[fk.column] as String?;
      if (value == null) {
        continue;
      }
      final targetRemap = remapByTable[fk.targetTable];
      final newValue = targetRemap?[value];
      if (newValue != null) {
        rewritten[fk.column] = newValue;
      }
    }

    return rewritten;
  }
}
