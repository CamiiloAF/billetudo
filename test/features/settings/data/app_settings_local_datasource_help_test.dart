import 'package:billetudo/core/database/app_database.dart' as db;
import 'package:billetudo/features/settings/data/datasources/app_settings_local_datasource.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

/// Covers `AppSettingsLocalDatasource.setShowHelpOnSectionEntry` — the
/// `settings`-side write path for the contextual-help preference
/// (`docs/requirements/fase-1/16-minitutoriales.md` HU-04), parallel to
/// `setZeroBasedEnabled` (already covered in
/// `app_settings_repository_impl_test.dart`).
void main() {
  late db.AppDatabase database;
  late AppSettingsLocalDatasource datasource;

  setUp(() {
    database = db.AppDatabase(NativeDatabase.memory());
    datasource = AppSettingsLocalDatasource(database);
  });

  tearDown(() async => database.close());

  test('defaults to true for a freshly-seeded singleton row', () async {
    final row = await datasource.readSettings();

    expect(row!.showHelpOnSectionEntry, isTrue);
  });

  test('persists the flag and upserts the singleton row', () async {
    await datasource.setShowHelpOnSectionEntry(
      showHelpOnSectionEntry: false,
      now: DateTime.now(),
    );

    final rows = await database.select(database.appSettings).get();

    expect(rows, hasLength(1));
    expect(rows.single.id, AppSettingsLocalDatasource.singletonId);
    expect(rows.single.showHelpOnSectionEntry, isFalse);
  });

  test('stamps updatedAt on every write', () async {
    await datasource.setShowHelpOnSectionEntry(
      showHelpOnSectionEntry: false,
      now: DateTime.now(),
    );
    final first = await database.select(database.appSettings).getSingle();

    await Future<void>.delayed(const Duration(milliseconds: 5));
    await datasource.setShowHelpOnSectionEntry(
      showHelpOnSectionEntry: true,
      now: DateTime.now(),
    );
    final second = await database.select(database.appSettings).getSingle();

    expect(second.updatedAt, greaterThan(first.updatedAt));
  });

  test('toggling twice does not create a second row', () async {
    await datasource.setShowHelpOnSectionEntry(
      showHelpOnSectionEntry: false,
      now: DateTime.now(),
    );
    await datasource.setShowHelpOnSectionEntry(
      showHelpOnSectionEntry: true,
      now: DateTime.now(),
    );

    final rows = await database.select(database.appSettings).get();

    expect(rows, hasLength(1));
    expect(rows.single.showHelpOnSectionEntry, isTrue);
  });
}
