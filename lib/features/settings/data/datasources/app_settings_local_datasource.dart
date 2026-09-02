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

  /// Records the AI assistant's third-party data-sharing consent as accepted
  /// now (Apple 5.1.2(i)), against the [consentVersion] of the copy that was
  /// actually shown.
  ///
  /// Both columns move in ONE write on purpose: a timestamp without its
  /// version (or the other way round) is a row that claims a consent nobody
  /// can date to a disclosure — and since the gate reads them together, a
  /// half-written pair would either re-ask forever or accept a stale consent.
  Future<void> markAiConsentAccepted({
    required DateTime now,
    required int consentVersion,
  }) =>
      _write(
        AppSettingsCompanion(
          aiConsentAcceptedAt: Value(now),
          aiConsentVersion: Value(consentVersion),
          updatedAt: Value(now.millisecondsSinceEpoch),
        ),
      );

  /// Withdraws the AI assistant's data-sharing consent (RGPD art. 7.3:
  /// withdrawing has to be as easy as giving it), putting the row back in the
  /// exact shape it had before anyone accepted.
  ///
  /// Three columns move in ONE write, and the third is not optional:
  /// `aiNotesAccessEnabled` is a *narrower* permission that only exists inside
  /// the broad one. Leaving it on after the broad consent is gone would be an
  /// orphan permission — the person believes they cancelled everything, while
  /// the row still says "yes, send my free-text notes".
  Future<void> clearAiConsent({required DateTime now}) => _write(
        AppSettingsCompanion(
          aiConsentAcceptedAt: const Value(null),
          aiConsentVersion: const Value(null),
          aiNotesAccessEnabled: const Value(false),
          updatedAt: Value(now.millisecondsSinceEpoch),
        ),
      );

  /// Turns the assistant's access to the records' free-text `note` on or off
  /// (`AppSettings.aiNotesAccessEnabled`). Off is the default and the
  /// privacy-preserving direction; nothing else in the row changes.
  Future<void> setAiNotesAccessEnabled({
    required bool enabled,
    required DateTime now,
  }) =>
      _write(
        AppSettingsCompanion(
          aiNotesAccessEnabled: Value(enabled),
          updatedAt: Value(now.millisecondsSinceEpoch),
        ),
      );

  /// `UPDATE` when the singleton exists, `INSERT` only when it is confirmed
  /// missing — never an upsert: `AppSettings` is physically a PowerSync-managed
  /// view (decision #14, docs/requirements/fase-1/05-auth-sync.md) and SQLite
  /// rejects `INSERT ... ON CONFLICT ... DO UPDATE` against a view outright
  /// (`cannot UPSERT a view`), whatever its `INSTEAD OF` triggers do.
  ///
  /// The row usually exists (`_seedAppSettings()` creates it on
  /// `onCreate`/migration), but it can legitimately be gone: wiping this
  /// device on sign-out (HU-06) goes through
  /// `PowerSyncDatabase.disconnectAndClear`, which empties every synced table
  /// including this one, and no migration re-runs afterwards. Without a
  /// fallback the seed latch could never be set again and the default
  /// categories would be re-seeded on every launch.
  ///
  /// BILLETUDO-? (found live, real device + real PowerSync + real Postgres,
  /// 2026-09-01): the previous version of this method ran `UPDATE`, then
  /// **unconditionally** ran `INSERT ... insertOrIgnore` afterwards too,
  /// trusting its own doc's claim that `insertOrIgnore` is a harmless no-op
  /// when the row already exists (justified at the time by
  /// `app_settings_after_wipe_test.dart`, which only ever exercised the
  /// *empty-row* case). It is not a no-op on an existing row against this
  /// PowerSync-managed view: every field **absent** from [values] still gets
  /// Drift's typed API to fill in its `clientDefault` (`id`, `createdAt`,
  /// `zeroBasedEnabled`, `categoriesSeeded`, `aiNotesAccessEnabled`, …) before
  /// the `INSTEAD OF INSERT` trigger runs, and that trigger applies them —
  /// confirmed by `createdAt` visibly changing to "now" on every single
  /// settings write, on a real device, in Postgres too. A column with a
  /// `clientDefault` and no explicit value in *that* write's [values] — e.g.
  /// `aiNotesAccessEnabled` when some *other* setting is the one being
  /// written — got silently reset to its Dart-side default. Nullable columns
  /// with no `clientDefault` (`aiConsentAcceptedAt`, `aiConsentVersion`)
  /// survived, which is exactly why the "notes toggle doesn't persist" bug
  /// looked notes-specific: it silently affected *every* `clientDefault`
  /// column, on *every* write to this table, not just this one.
  ///
  /// The fix: ask the row whether it exists with a real `SELECT` first, and
  /// only take the insert path when it is genuinely missing. A `SELECT`
  /// against this view returns real rows (unlike the `UPDATE`/`INSERT`
  /// side, its `changes()` problem is specific to DML through `INSTEAD OF`
  /// triggers), so this is a reliable existence check where the row's own
  /// affected-row count never was.
  ///
  /// The insert branch still ends with one plain `UPDATE` of its own — that
  /// part of the original design was correct and stays
  /// (`app_settings_local_datasource_write_race_test.dart` covers exactly
  /// why): a concurrent reseed (`_seedAppSettings()` right after a sign-out
  /// wipe) can recreate the row in the gap between the `SELECT` above and
  /// this `INSERT`, making `insertOrIgnore` a silent no-op that drops
  /// [values]. This does **not** reintroduce the bug this whole rewrite
  /// exists to fix: `clientDefault` only fires when Drift builds an `INSERT`
  /// statement for an absent field, never for a plain `UPDATE` — so this
  /// follow-up `UPDATE`, restricted to the missing-row branch instead of
  /// running after every single write, reasserts [values] without touching
  /// any sibling column's default.
  Future<void> _write(AppSettingsCompanion values) async {
    final exists = await (_db.select(_db.appSettings)
          ..where((s) => s.id.equals(singletonId)))
        .getSingleOrNull();
    if (exists == null) {
      await _db.into(_db.appSettings).insert(
            values.copyWith(id: const Value(singletonId)),
            mode: InsertMode.insertOrIgnore,
          );
      await (_db.update(_db.appSettings)
            ..where((s) => s.id.equals(singletonId)))
          .write(values);
      return;
    }
    await (_db.update(_db.appSettings)..where((s) => s.id.equals(singletonId)))
        .write(values);
  }
}
