import 'package:billetudo/core/database/app_database.dart' as db;
import 'package:billetudo/features/settings/data/datasources/app_settings_local_datasource.dart';
import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

/// Covers `AppSettingsLocalDatasource._write`'s fallback path: `UPDATE`
/// finds 0 rows (the singleton is momentarily absent), so it falls back to
/// `INSERT ... insertOrIgnore`.
///
/// The bug this guards against: if something else (in production, the
/// `_seedAppSettings()` reseed that follows `PowerSyncDatabase
/// .disconnectAndClear`) recreates the singleton row in the gap between the
/// failed `UPDATE` and the fallback `INSERT`, `insertOrIgnore` silently does
/// nothing — a row with the singleton id already exists again — and the
/// caller's explicit values (e.g. `setFeaturedBudget`'s `manual` +
/// `featuredBudgetId`) are dropped in favor of whatever the reseed wrote
/// (the `clientDefault` `automatic`/`none`). `_write` must retry the
/// `UPDATE` once more so this race never wins over an explicit write.
///
/// The race is reproduced deterministically (no real concurrency, no
/// flakiness) with a `QueryInterceptor`: the moment `_write`'s own fallback
/// `INSERT` runs, the interceptor first performs the "concurrent reseed"
/// itself, then lets the real statement proceed — reproducing exactly the
/// interleaving the bug depends on.
void main() {
  late _ReseedOnNextInsertInterceptor interceptor;
  late db.AppDatabase database;
  late AppSettingsLocalDatasource datasource;

  setUp(() {
    interceptor = _ReseedOnNextInsertInterceptor();
    final connection =
        DatabaseConnection(NativeDatabase.memory()).interceptWith(interceptor);
    database = db.AppDatabase(connection);
    interceptor.database = database;
    datasource = AppSettingsLocalDatasource(database);
  });

  tearDown(() async => database.close());

  test(
      'a reseed racing between the failed UPDATE and the fallback INSERT '
      'does not silently drop an explicit write', () async {
    // The singleton row exists from `onCreate`'s own seed; delete it to
    // reproduce the "momentarily absent" precondition the fallback path
    // exists for (e.g. right after `disconnectAndClear`).
    await database.delete(database.appSettings).go();
    expect(await datasource.readSettings(), isNull);

    // Arm the interceptor: the next `INSERT` (the fallback `insertOrIgnore`
    // inside `_write`) will be preceded by a concurrent reseed that
    // recreates the row with plain defaults first.
    interceptor.armed = true;

    await datasource.setFeaturedBudget(
      budgetId: 'budget-1',
      now: DateTime.fromMillisecondsSinceEpoch(1000),
    );

    final row = await datasource.readSettings();
    expect(
      row,
      isNotNull,
      reason: 'the singleton must exist — either write recreated it',
    );
    expect(
      row!.featuredBudgetId,
      'budget-1',
      reason: 'the explicit setFeaturedBudget() value must win over the racing '
          'reseed default, never get silently dropped by insertOrIgnore',
    );
    expect(row.featuredBudgetMode, db.FeaturedBudgetMode.manual);

    final rows = await database.select(database.appSettings).get();
    expect(
      rows,
      hasLength(1),
      reason: 'the race must never leave two singleton rows behind either',
    );
  });

  test(
      'without a race (no reseed in the gap), the same fallback path still '
      'self-heals as before', () async {
    await database.delete(database.appSettings).go();

    await datasource.setFeaturedBudget(
      budgetId: 'budget-2',
      now: DateTime.fromMillisecondsSinceEpoch(2000),
    );

    final row = await datasource.readSettings();
    expect(row!.featuredBudgetId, 'budget-2');
    expect(row.featuredBudgetMode, db.FeaturedBudgetMode.manual);
  });
}

/// Simulates a concurrent `_seedAppSettings()` reseed landing in the gap
/// between `_write`'s failed `UPDATE` and its fallback
/// `INSERT ... insertOrIgnore`: the first time [armed] is set and an
/// `INSERT` runs on the intercepted connection, this interceptor performs
/// that reseed itself (through the same [database], so it goes through this
/// same interceptor and is not re-triggered — [armed] is cleared first)
/// before letting the original statement proceed.
class _ReseedOnNextInsertInterceptor extends QueryInterceptor {
  bool armed = false;
  late db.AppDatabase database;

  @override
  Future<int> runInsert(
    QueryExecutor executor,
    String statement,
    List<Object?> args,
  ) async {
    if (armed) {
      armed = false;
      await database.into(database.appSettings).insert(
            const db.AppSettingsCompanion(),
            mode: InsertMode.insertOrIgnore,
          );
    }
    return executor.runInsert(statement, args);
  }
}
