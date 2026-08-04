import 'package:billetudo/core/database/app_database.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

/// Regression test for the v21 -> v22 migration (BILLETUDO-9/BILLETUDO-A):
/// a singleton `app_settings` row created before `onboardingCompleted`
/// existed has no `onboarding_completed` key in its PowerSync JSON blob, so
/// the view reads it as SQL NULL — Drift's generated non-nullable mapper does
/// a `!` on that and crashes (`TypeError: Null check operator used on a null
/// value`, `$AppSettingsTable.map`).
///
/// Like every other Drift schema test in this repo (see `goals_schema_test.dart`),
/// this exercises the *backfill SQL itself* against a plain in-memory
/// `NativeDatabase`, not the real `onUpgrade` path: `app_settings` is only a
/// real (non-view) table here, since a plain `NativeDatabase` has none of
/// PowerSync's `ps_data_`/view machinery.
///
/// `onCreate` builds `app_settings` with a real SQL `NOT NULL` constraint on
/// `onboarding_completed` (Drift derives it from the non-nullable Dart `bool`
/// column) — production's PowerSync *view* has no such constraint, since
/// every column there is just a `CAST(json_extract(data, '$.col') AS ...)`
/// that silently yields NULL for a missing JSON key. The table is rebuilt by
/// hand below (same name/columns, `onboarding_completed` nullable) so the
/// NULL row can actually exist, matching what the real view allows.
void main() {
  late AppDatabase database;

  setUp(() async {
    database = AppDatabase(NativeDatabase.memory());
    await database.customStatement('DROP TABLE app_settings');
    await database.customStatement('''
      CREATE TABLE app_settings (
        id TEXT NOT NULL PRIMARY KEY,
        created_at INTEGER NOT NULL,
        updated_at INTEGER NOT NULL,
        deleted_at INTEGER,
        tombstoned_at INTEGER,
        user_id TEXT,
        zero_based_enabled INTEGER NOT NULL,
        categories_seeded INTEGER NOT NULL,
        onboarding_completed INTEGER
      )
    ''');
    await database.customStatement('''
      INSERT INTO app_settings
        (id, created_at, updated_at, zero_based_enabled, categories_seeded, onboarding_completed)
      VALUES ('app', 0, 0, 0, 0, NULL)
    ''');
  });

  tearDown(() async => database.close());

  test(
    'a NULL onboarding_completed crashes the read, exactly reproducing '
    'BILLETUDO-9/BILLETUDO-A',
    () async {
      expect(
        () => database.select(database.appSettings).getSingleOrNull(),
        throwsA(isA<TypeError>()),
      );
    },
  );

  test(
    'the v21 -> v22 backfill (UPDATE ... WHERE onboarding_completed IS NULL) '
    'heals the row and the read succeeds again',
    () async {
      // The exact statement the `from < 22` migration block runs.
      await database.customStatement(
        'UPDATE app_settings SET onboarding_completed = 0 '
        'WHERE onboarding_completed IS NULL',
      );

      final row = await database.select(database.appSettings).getSingleOrNull();
      expect(row, isNotNull);
      expect(row!.onboardingCompleted, isFalse);
    },
  );
}
