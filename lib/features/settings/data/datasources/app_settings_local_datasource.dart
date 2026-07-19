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
  ///
  /// A plain `UPDATE`, not an upsert: `AppSettings` is physically a
  /// PowerSync-managed view (see decision #14, docs/requirements/05-auth-sync.md),
  /// and SQLite rejects `INSERT ... ON CONFLICT ... DO UPDATE` against a view
  /// outright (`cannot UPSERT a view`) regardless of its `INSTEAD OF` triggers.
  /// Safe as a plain update because the singleton row always exists already
  /// — `_seedAppSettings()` creates it on `onCreate`/migration — so the
  /// "insert" branch of an upsert is never actually needed here.
  Future<void> markCategoriesSeeded({required DateTime now}) =>
      (_db.update(_db.appSettings)..where((s) => s.id.equals(singletonId)))
          .write(
        AppSettingsCompanion(
          categoriesSeeded: const Value(true),
          updatedAt: Value(now.millisecondsSinceEpoch),
        ),
      );

  /// Updates the singleton's [zeroBasedEnabled]. See [markCategoriesSeeded]
  /// for why this is a plain `UPDATE`, never an upsert.
  Future<void> setZeroBasedEnabled({
    required bool zeroBasedEnabled,
    required DateTime now,
  }) =>
      (_db.update(_db.appSettings)..where((s) => s.id.equals(singletonId)))
          .write(
        AppSettingsCompanion(
          zeroBasedEnabled: Value(zeroBasedEnabled),
          updatedAt: Value(now.millisecondsSinceEpoch),
        ),
      );
}
