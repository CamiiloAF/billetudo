import 'package:drift/drift.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/database/app_database.dart';

/// Drift access to the `AppSettings` singleton (id `'app'`).
///
/// Every write targets that one constant id — the row is a true singleton, so
/// there is never a second row to reconcile. Writes upsert (rather than blind
/// update) so a missing row self-heals, and always stamp `updatedAt` for
/// PowerSync's last-write-wins merge.
@lazySingleton
class AppSettingsLocalDatasource {
  const AppSettingsLocalDatasource(this._db);

  /// The well-known constant id of the settings singleton (see `AppSettings`
  /// table doc: not a random UUID, so two offline devices never diverge).
  static const String singletonId = 'app';

  final AppDatabase _db;

  Stream<AppSetting?> watchSettings() =>
      (_db.select(_db.appSettings)..where((s) => s.id.equals(singletonId)))
          .watchSingleOrNull();

  /// One-shot read of the singleton (not a stream): callers that only need the
  /// current value once — e.g. the seed latch — should use this.
  Future<AppSetting?> readSettings() =>
      (_db.select(_db.appSettings)..where((s) => s.id.equals(singletonId)))
          .getSingleOrNull();

  /// Marks the onboarding default categories as seeded for this installation.
  Future<void> markCategoriesSeeded({required DateTime now}) => _write(
        AppSettingsCompanion(
          categoriesSeeded: const Value(true),
          updatedAt: Value(now.millisecondsSinceEpoch),
        ),
      );

  /// Updates the singleton's [zeroBasedEnabled].
  Future<void> setZeroBasedEnabled({
    required bool zeroBasedEnabled,
    required DateTime now,
  }) =>
      _write(
        AppSettingsCompanion(
          zeroBasedEnabled: Value(zeroBasedEnabled),
          updatedAt: Value(now.millisecondsSinceEpoch),
        ),
      );

  /// `UPDATE`, falling back to `INSERT` when the singleton is missing — never
  /// an upsert: `AppSettings` is physically a PowerSync-managed view (decision
  /// #14, docs/requirements/05-auth-sync.md) and SQLite rejects
  /// `INSERT ... ON CONFLICT ... DO UPDATE` against a view outright
  /// (`cannot UPSERT a view`), whatever its `INSTEAD OF` triggers do.
  ///
  /// The row usually exists (`_seedAppSettings()` creates it on
  /// `onCreate`/migration), but it can legitimately be gone: wiping this
  /// device on sign-out (HU-06) goes through
  /// `PowerSyncDatabase.disconnectAndClear`, which empties every synced table
  /// including this one, and no migration re-runs afterwards. Without this
  /// fallback the seed latch could never be set again and the default
  /// categories would be re-seeded on every launch.
  Future<void> _write(AppSettingsCompanion values) async {
    final updated = await (_db.update(_db.appSettings)
          ..where((s) => s.id.equals(singletonId)))
        .write(values);
    if (updated > 0) {
      return;
    }
    await _db.into(_db.appSettings).insert(
          values.copyWith(id: const Value(singletonId)),
          mode: InsertMode.insertOrIgnore,
        );
  }
}
