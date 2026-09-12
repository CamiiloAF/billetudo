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
///
/// `featured_budget_mode` (schemaVersion 26) is included too, even though
/// this test predates it, purely so the generated non-nullable mapper for
/// that column doesn't crash on an unrelated missing column while reading
/// the row — it is pre-populated so it never participates in the
/// `onboarding_completed` NULL scenario under test here.
///
/// `ai_notes_access_enabled` (schemaVersion 32) is the same class of bug all
/// over again — non-nullable in Dart, absent from the JSON blob of any row
/// written before v32 — so it is declared nullable and inserted NULL, exactly
/// like `show_help_on_section_entry`, and healed by its own `from < 32`
/// backfill below.
///
/// `ai_consent_version` (also schemaVersion 32) is declared and inserted NULL
/// as well, but as a *control*, not as a second crash: it is nullable by
/// design and deliberately NOT backfilled (see the `from < 32` block, which
/// explains that writing a fabricated `0` could clobber a real value from
/// another device through PowerSync's upsert). The assertion below pins that
/// it survives the read as `null` — the read layer's "version 0".
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
        onboarding_completed INTEGER,
        show_help_on_section_entry INTEGER,
        featured_budget_mode TEXT NOT NULL DEFAULT 'automatic',
        ai_consent_accepted_at INTEGER,
        ai_consent_version INTEGER,
        ai_notes_access_enabled INTEGER
      )
    ''');
    await database.customStatement('''
      INSERT INTO app_settings
        (id, created_at, updated_at, zero_based_enabled, categories_seeded, onboarding_completed, show_help_on_section_entry, featured_budget_mode, ai_consent_accepted_at, ai_consent_version, ai_notes_access_enabled)
      VALUES ('app', 0, 0, 0, 0, NULL, NULL, 'automatic', NULL, NULL, NULL)
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
    'a NULL ai_notes_access_enabled reproduces the same crash on its own, '
    'even once the older non-nullable columns are healed',
    () async {
      await database.customStatement(
        'UPDATE app_settings SET onboarding_completed = 0 '
        'WHERE onboarding_completed IS NULL',
      );
      await database.customStatement(
        'UPDATE app_settings SET show_help_on_section_entry = 1 '
        'WHERE show_help_on_section_entry IS NULL',
      );

      // Only `ai_notes_access_enabled` is still NULL: the read must still
      // blow up, or the `from < 32` backfill below would be untested.
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
      // The exact statement the `from < 24` migration block runs for the
      // same class of NULL-key bug on `show_help_on_section_entry`.
      await database.customStatement(
        'UPDATE app_settings SET show_help_on_section_entry = 1 '
        'WHERE show_help_on_section_entry IS NULL',
      );
      // The exact statement the `from < 32` migration block runs, for the
      // same class of bug on `ai_notes_access_enabled`.
      await database.customStatement(
        'UPDATE app_settings SET ai_notes_access_enabled = 0 '
        'WHERE ai_notes_access_enabled IS NULL',
      );

      final row = await database.select(database.appSettings).getSingleOrNull();
      expect(row, isNotNull);
      expect(row!.onboardingCompleted, isFalse);
      expect(row.showHelpOnSectionEntry, isTrue);
      // Backfilled to the privacy-safe default: notes stay out of AI reach
      // until the user opts in explicitly.
      expect(row.aiNotesAccessEnabled, isFalse);
      // Deliberately NOT backfilled: nullable by design, read as "version 0".
      expect(row.aiConsentVersion, isNull);
    },
  );
}
