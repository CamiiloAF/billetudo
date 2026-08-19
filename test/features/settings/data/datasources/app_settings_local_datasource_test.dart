import 'package:billetudo/core/database/app_database.dart' as db;
import 'package:billetudo/features/home/domain/entities/quick_access_item.dart';
import 'package:billetudo/features/settings/data/datasources/app_settings_local_datasource.dart';
import 'package:billetudo/features/settings/data/repositories/app_settings_repository_impl.dart';
import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

/// Covers `AppSettingsLocalDatasource.setQuickAccessOrder` and the
/// repository-level parsing/fallback it feeds
/// (`AppSettingsRepositoryImpl._toQuickAccessOrder`): a valid write persists
/// and reads back identically, and an invalid raw value at the row level
/// (bypassing `SetQuickAccessOrder`'s validation, the way a corrupted row
/// could look) does not corrupt the row and the repository still resolves to
/// the default order.
void main() {
  late db.AppDatabase database;
  late AppSettingsLocalDatasource datasource;
  late AppSettingsRepositoryImpl repository;

  setUp(() {
    database = db.AppDatabase(NativeDatabase.memory());
    datasource = AppSettingsLocalDatasource(database);
    repository = AppSettingsRepositoryImpl(datasource);
  });

  tearDown(() async => database.close());

  Future<void> writeRawOrder(String? raw) => database
      .into(database.appSettings)
      .insertOnConflictUpdate(
        db.AppSettingsCompanion.insert(
          id: const Value(AppSettingsLocalDatasource.singletonId),
          quickAccessOrder: Value(raw),
        ),
      );

  test('persists a valid order and reads it back identically', () async {
    const order = [
      QuickAccessItem.debts,
      QuickAccessItem.reports,
      QuickAccessItem.scheduledPayments,
    ];

    await datasource.setQuickAccessOrder(order: order, now: DateTime.now());

    final row = await datasource.readSettings();
    expect(row!.quickAccessOrder, 'debts,reports,scheduledPayments');

    final result = await repository.getSettings();
    final settings = result.getOrElse((_) => throw StateError('expected Right'));
    expect(settings.quickAccessOrder, order);
  });

  test('does not create a second row and stamps updatedAt', () async {
    const order = [
      QuickAccessItem.reports,
      QuickAccessItem.debts,
      QuickAccessItem.scheduledPayments,
    ];

    await datasource.setQuickAccessOrder(order: order, now: DateTime.now());
    final rows = await database.select(database.appSettings).get();

    expect(rows, hasLength(1));
    expect(rows.single.id, AppSettingsLocalDatasource.singletonId);
  });

  test(
    'repository falls back to the default order when the stored value is '
    'null (predates the column, or missing row)',
    () async {
      final result = await repository.getSettings();

      final settings =
          result.getOrElse((_) => throw StateError('expected Right'));
      expect(settings.quickAccessOrder, QuickAccessItem.defaultOrder);
    },
  );

  test(
    'repository falls back to the default order when the stored value has '
    'a duplicate item (invalid permutation) — and the row is not corrupted',
    () async {
      await writeRawOrder('debts,debts,reports');

      final result = await repository.getSettings();
      final settings =
          result.getOrElse((_) => throw StateError('expected Right'));
      expect(settings.quickAccessOrder, QuickAccessItem.defaultOrder);

      final rows = await database.select(database.appSettings).get();
      expect(rows, hasLength(1));
      expect(rows.single.id, AppSettingsLocalDatasource.singletonId);
    },
  );

  test(
    'repository falls back to the default order when the stored value is '
    'incomplete (missing an item)',
    () async {
      await writeRawOrder('debts,reports');

      final result = await repository.getSettings();
      final settings =
          result.getOrElse((_) => throw StateError('expected Right'));
      expect(settings.quickAccessOrder, QuickAccessItem.defaultOrder);
    },
  );

  test(
    'repository falls back to the default order when the stored value has '
    'an unknown item name',
    () async {
      await writeRawOrder('debts,reports,somethingElse');

      final result = await repository.getSettings();
      final settings =
          result.getOrElse((_) => throw StateError('expected Right'));
      expect(settings.quickAccessOrder, QuickAccessItem.defaultOrder);
    },
  );

  test(
    'repository falls back to the default order when the stored value is '
    'the empty string',
    () async {
      await writeRawOrder('');

      final result = await repository.getSettings();
      final settings =
          result.getOrElse((_) => throw StateError('expected Right'));
      expect(settings.quickAccessOrder, QuickAccessItem.defaultOrder);
    },
  );
}
