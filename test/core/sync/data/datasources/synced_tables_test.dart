import 'package:billetudo/core/database/app_database.dart';
import 'package:billetudo/core/sync/data/datasources/synced_tables.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

/// Regression test for the 2026-09-10 bug fixed in
/// `lib/core/sync/data/datasources/synced_tables.dart`: `ownedTables` was
/// hand-maintained and silently drifted from the real schema — 7 tables that
/// carry `_SyncColumns.userId` (`goal_contributions`, `goal_quick_amounts`,
/// `debt_entries`, `scheduled_payment_occurrences`,
/// `scheduled_payment_tags`, `import_batches`, `tutorial_views`) were missing,
/// so rows created while signed out never got claimed on login (HU-04).
///
/// Rather than duplicating a second hardcoded list here (which would rot the
/// same way), this test asks Drift itself, via `AppDatabase.allTables`,
/// which tables actually have a `user_id` column and compares that live set
/// against `ownedTables`. It fails if a future table gains `user_id` without
/// being added here, or if an entry in `ownedTables` stops corresponding to
/// a real table.
void main() {
  test(
    'ownedTables matches exactly the set of tables with a user_id column '
    'in AppDatabase',
    () async {
      final database = AppDatabase(NativeDatabase.memory());
      addTearDown(database.close);

      final tablesWithUserId = database.allTables
          .where(
            (table) => table.$columns.any((column) => column.name == 'user_id'),
          )
          .map((table) => table.actualTableName)
          .toSet();

      final declaredOwnedTables = ownedTables.toSet();

      expect(
        declaredOwnedTables.length,
        ownedTables.length,
        reason: 'ownedTables has duplicate entries',
      );

      final missingFromOwnedTables =
          tablesWithUserId.difference(declaredOwnedTables);
      expect(
        missingFromOwnedTables,
        isEmpty,
        reason: 'These tables have a user_id column in AppDatabase but are '
            'missing from ownedTables, so rows created while signed out '
            'will never be claimed on login: $missingFromOwnedTables',
      );

      final staleInOwnedTables =
          declaredOwnedTables.difference(tablesWithUserId);
      expect(
        staleInOwnedTables,
        isEmpty,
        reason: 'These entries in ownedTables no longer correspond to a '
            'table with a user_id column in AppDatabase (renamed, dropped, '
            'or the column was removed): $staleInOwnedTables',
      );
    },
  );
}
