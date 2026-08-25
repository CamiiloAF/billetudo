import 'dart:io';

import 'package:billetudo/core/database/app_database.dart' as db;
import 'package:billetudo/features/settings/data/datasources/app_settings_local_datasource.dart';
import 'package:billetudo/features/settings/data/repositories/app_settings_repository_impl.dart';
import 'package:billetudo/features/settings/domain/entities/app_settings.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

/// Regression test for decision #25
/// (`docs/requirements/fase-1/05-auth-sync.md`): a device whose PowerSync
/// store synced before `featured_budget_mode` existed has a *physically*
/// `NULL` value in that column — not "never configured". The old `from < 26`
/// migration treated that `NULL` as unconfigured and backfilled it to
/// `'automatic'`, and that local write then propagated to Postgres via
/// PowerSync's merge-duplicates upsert, silently clobbering the user's real
/// server value (e.g. `manual`).
///
/// The fix: `featuredBudgetMode` is nullable in Drift, the backfill is gone,
/// and `null` is interpreted as `automatic` only in the read/mapping layer
/// (`AppSettingsRepositoryImpl._toFeaturedBudgetMode`) — never written back
/// to the row.
void main() {
  late db.AppDatabase database;
  late AppSettingsRepositoryImpl repository;

  setUp(() {
    database = db.AppDatabase(NativeDatabase.memory());
    repository = AppSettingsRepositoryImpl(
      AppSettingsLocalDatasource(database),
    );
  });

  tearDown(() async => database.close());

  /// `_seedAppSettings()` (`onCreate`) already creates the singleton row —
  /// this forces its `featured_budget_mode` to a physical SQL `NULL`,
  /// bypassing Drift's typed writes (which always write a value), to
  /// reproduce the real shape of a row that synced down from PowerSync
  /// before the column existed. `updated_at` is stamped to a known sentinel
  /// so a later test can assert nothing wrote to the row afterwards.
  Future<void> forceNullFeaturedBudgetMode() => database.customStatement(
        'UPDATE app_settings SET featured_budget_mode = NULL, '
        'updated_at = 0 '
        "WHERE id = '${AppSettingsLocalDatasource.singletonId}'",
      );

  test(
    'a physically NULL featured_budget_mode does not crash the read',
    () async {
      await forceNullFeaturedBudgetMode();

      expect(
        () => database.select(database.appSettings).getSingleOrNull(),
        returnsNormally,
      );
      final row =
          await database.select(database.appSettings).getSingleOrNull();
      expect(row!.featuredBudgetMode, isNull);
    },
  );

  test(
    'getSettings() maps a NULL featured_budget_mode to automatic without '
    'writing anything back to the row',
    () async {
      await forceNullFeaturedBudgetMode();

      final result = await repository.getSettings();
      final settings = result.getRight().toNullable()!;
      expect(settings.featuredBudgetMode, FeaturedBudgetMode.automatic);

      // The read must not have persisted anything back: the physical row
      // still has featured_budget_mode = NULL and the same sentinel
      // updatedAt stamped above.
      final row =
          await database.select(database.appSettings).getSingleOrNull();
      expect(row!.featuredBudgetMode, isNull);
      expect(row.updatedAt, 0);
    },
  );

  test(
    'the from < 26 migration block no longer contains a backfill UPDATE '
    'over featured_budget_mode (the exact statement that corrupted real '
    'server data, see decision #25)',
    () {
      final source = File(
        p.join(p.current, 'lib', 'core', 'database', 'app_database.dart'),
      ).readAsStringSync();

      expect(
        source,
        isNot(
          contains(
            "UPDATE app_settings SET featured_budget_mode = 'automatic'",
          ),
        ),
        reason: 'this exact UPDATE clobbered real user data by treating a '
            'not-yet-synced NULL as "never configured" (decision #25, '
            'docs/requirements/fase-1/05-auth-sync.md) — it must not come '
            'back.',
      );
    },
  );
}
