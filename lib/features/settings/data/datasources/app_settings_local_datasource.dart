import 'package:drift/drift.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/database/app_database.dart';
import '../../../home/domain/entities/quick_access_item.dart';

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

  /// Marks the welcome flow (`docs/requirements/fase-1/13-onboarding.md`) as
  /// completed for this installation.
  Future<void> markOnboardingCompleted({required DateTime now}) => _write(
        AppSettingsCompanion(
          onboardingCompleted: const Value(true),
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

  /// Updates the singleton's [showHelpOnSectionEntry] (contextual-help
  /// minitutorials, `docs/requirements/fase-1/16-minitutoriales.md` HU-04).
  /// Paralelo a [setZeroBasedEnabled]. Note: `tutorials`' own
  /// `TutorialViewsLocalDatasource` also writes this same column directly
  /// (documented there) to avoid a cross-feature `data/` dependency — both
  /// target the identical singleton row and constant id, so the two never
  /// diverge.
  Future<void> setShowHelpOnSectionEntry({
    required bool showHelpOnSectionEntry,
    required DateTime now,
  }) =>
      _write(
        AppSettingsCompanion(
          showHelpOnSectionEntry: Value(showHelpOnSectionEntry),
          updatedAt: Value(now.millisecondsSinceEpoch),
        ),
      );

  /// Sets the singleton's `featuredBudgetId` to an explicit manual pick and
  /// flips `featuredBudgetMode` to `manual` in the same write, so the two
  /// columns never disagree (an id with a stale `automatic`/`none` mode).
  Future<void> setFeaturedBudget({
    required String budgetId,
    required DateTime now,
  }) =>
      _write(
        AppSettingsCompanion(
          featuredBudgetId: Value(budgetId),
          featuredBudgetMode: const Value(FeaturedBudgetMode.manual),
          updatedAt: Value(now.millisecondsSinceEpoch),
        ),
      );

  /// Clears the featured budget entirely: `featuredBudgetMode` goes to
  /// `none` (no automatic fallback either — see `FeaturedBudgetMode`) and
  /// `featuredBudgetId` is reset to `null` since it stops being relevant.
  Future<void> clearFeaturedBudget({required DateTime now}) => _write(
        AppSettingsCompanion(
          featuredBudgetId: const Value(null),
          featuredBudgetMode: const Value(FeaturedBudgetMode.none),
          updatedAt: Value(now.millisecondsSinceEpoch),
        ),
      );

  /// Persists the Home quick-access chips' order (`QuickAccessRow`) as a
  /// comma-separated list of [order]'s `.name` values (e.g.
  /// `'debts,scheduledPayments,reports'`). [order] is trusted to already be a
  /// valid permutation — `SetQuickAccessOrder` (domain) is the one that
  /// validates it; this datasource only serializes and writes.
  Future<void> setQuickAccessOrder({
    required List<QuickAccessItem> order,
    required DateTime now,
  }) =>
      _write(
        AppSettingsCompanion(
          quickAccessOrder: Value(order.map((item) => item.name).join(',')),
          updatedAt: Value(now.millisecondsSinceEpoch),
        ),
      );

  /// `UPDATE`, falling back to `INSERT` when the singleton is missing — never
  /// an upsert: `AppSettings` is physically a PowerSync-managed view (decision
  /// #14, docs/requirements/fase-1/05-auth-sync.md) and SQLite rejects
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
  ///
  /// The `UPDATE` finding 0 rows and, in the gap before the fallback
  /// `INSERT ... insertOrIgnore` below runs, something else (most likely
  /// `_seedAppSettings()`'s own reseed, e.g. right after a sign-out wipe)
  /// recreating the singleton row means `insertOrIgnore` silently drops
  /// [values] — a row with `singletonId` already exists again, so the insert
  /// is a no-op, and only the freshly-reseeded defaults survive.
  ///
  /// The follow-up `UPDATE` after the insert closes that gap: if the insert
  /// above created the row, this is a harmless no-op re-write of the same
  /// [values]; if it didn't (the race), this is what actually persists them.
  ///
  /// Its own affected-row count is **not** checked, unlike the first
  /// `UPDATE` above. Confirmed empirically against a real PowerSync
  /// connection (`app_settings_after_wipe_test.dart` uses one, not a plain
  /// in-memory `NativeDatabase`): SQLite's `changes()` does not count writes
  /// performed by an `INSTEAD OF` trigger body, so *every* `UPDATE` against
  /// this view reports `0` regardless of whether it actually matched and
  /// updated the row — including the very first `UPDATE` above when it
  /// *does* find and update an existing row. (That first `UPDATE`'s `0`
  /// still doubles as "go to the fallback" correctly: the fallback's own
  /// `insertOrIgnore` is a safe no-op on a row that in fact already got
  /// updated, so relying on it there was never actually wrong, just
  /// coincidentally-named — this data source never had a working
  /// affected-row signal to test in the first place.) So there is nothing
  /// left to gate the retry on; running it unconditionally and trusting its
  /// result is the correct behavior for this table, not a shortcut.
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
    await (_db.update(_db.appSettings)..where((s) => s.id.equals(singletonId)))
        .write(values);
  }
}
