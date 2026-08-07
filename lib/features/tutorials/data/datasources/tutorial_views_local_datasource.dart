import 'package:drift/drift.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/database/app_database.dart';
import '../../domain/entities/tutorial_key.dart';

/// Drift access to the contextual-help minitutorials' "already seen"
/// registry (`TutorialViews`) plus the `AppSettings.showHelpOnSectionEntry`
/// preference (`docs/requirements/16-minitutoriales.md`).
///
/// `TutorialViews.id` is [TutorialKey.id] — a small stable string, NOT a
/// generated UUID (see the table's class doc in `app_database.dart`): row
/// presence means "seen", there is no boolean column to flip.
///
/// Reads/writes the `AppSettings` singleton row directly for the one column
/// this feature owns rather than depending on the `settings` feature's own
/// datasource, keeping `data/` cross-feature-free the same way every other
/// feature's datasource only ever imports `core/database`.
@lazySingleton
class TutorialViewsLocalDatasource {
  const TutorialViewsLocalDatasource(this._db);

  /// The well-known constant id of the `AppSettings` singleton (same value
  /// as `AppSettingsLocalDatasource.singletonId` in the `settings` feature —
  /// duplicated here on purpose to avoid a cross-feature data dependency).
  static const String settingsSingletonId = 'app';

  final AppDatabase _db;

  /// Whether a row exists for [key] — presence means seen.
  Future<bool> hasSeen(TutorialKey key) async {
    final row = await (_db.select(_db.tutorialViews)
          ..where((t) => t.id.equals(key.id)))
        .getSingleOrNull();
    return row != null;
  }

  /// Inserts (or leaves untouched, if already present) a row for [key].
  Future<void> markSeen(TutorialKey key, {required DateTime now}) =>
      _db.into(_db.tutorialViews).insert(
            TutorialViewsCompanion.insert(
              id: key.id,
              updatedAt: Value(now.millisecondsSinceEpoch),
            ),
            mode: InsertMode.insertOrIgnore,
          );

  /// Deletes every row — every tutorial becomes "not seen" again (HU-04).
  /// A hard delete, not a `deletedAt` soft-delete: this is a reset of a
  /// derived "seen" signal, not a trash the user can undo (see CLAUDE.md's
  /// `deletedAt`/`tombstonedAt` distinction — neither applies here).
  Future<void> deleteAll() => _db.delete(_db.tutorialViews).go();

  /// One-shot read of `AppSettings.showHelpOnSectionEntry`. Defaults to
  /// `true` (the documented default) when the singleton row is missing.
  Future<bool> readHelpEnabled() async {
    final row = await (_db.select(_db.appSettings)
          ..where((s) => s.id.equals(settingsSingletonId)))
        .getSingleOrNull();
    return row?.showHelpOnSectionEntry ?? true;
  }

  /// Reactive read of `AppSettings.showHelpOnSectionEntry`.
  Stream<bool> watchHelpEnabled() => (_db.select(_db.appSettings)
        ..where((s) => s.id.equals(settingsSingletonId)))
      .watchSingleOrNull()
      .map((row) => row?.showHelpOnSectionEntry ?? true);

  /// `UPDATE`, falling back to `INSERT` when the singleton is missing — same
  /// upsert-via-fallback pattern as `AppSettingsLocalDatasource._write`
  /// (`appSettings` is a PowerSync-managed view; SQLite rejects
  /// `INSERT ... ON CONFLICT ... DO UPDATE` against a view).
  Future<void> setHelpEnabled({
    required bool enabled,
    required DateTime now,
  }) async {
    final values = AppSettingsCompanion(
      showHelpOnSectionEntry: Value(enabled),
      updatedAt: Value(now.millisecondsSinceEpoch),
    );
    final updated = await (_db.update(_db.appSettings)
          ..where((s) => s.id.equals(settingsSingletonId)))
        .write(values);
    if (updated > 0) {
      return;
    }
    await _db.into(_db.appSettings).insert(
          values.copyWith(id: const Value(settingsSingletonId)),
          mode: InsertMode.insertOrIgnore,
        );
  }
}
