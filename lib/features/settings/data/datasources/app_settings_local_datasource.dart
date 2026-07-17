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
  /// Upserts on the constant id (like [setZeroBasedEnabled]) so it can never
  /// create a second row, and stamps [now] into `updatedAt`.
  Future<void> markCategoriesSeeded({required DateTime now}) =>
      _db.into(_db.appSettings).insertOnConflictUpdate(
            AppSettingsCompanion.insert(
              id: const Value(singletonId),
              categoriesSeeded: const Value(true),
              updatedAt: Value(now.millisecondsSinceEpoch),
            ),
          );

  /// Upserts the singleton with [zeroBasedEnabled]. Uses `insertOnConflictUpdate`
  /// keyed on the constant id so it can never create a second row.
  Future<void> setZeroBasedEnabled({
    required bool zeroBasedEnabled,
    required DateTime now,
  }) =>
      _db.into(_db.appSettings).insertOnConflictUpdate(
            AppSettingsCompanion.insert(
              id: const Value(singletonId),
              zeroBasedEnabled: Value(zeroBasedEnabled),
              updatedAt: Value(now.millisecondsSinceEpoch),
            ),
          );
}
