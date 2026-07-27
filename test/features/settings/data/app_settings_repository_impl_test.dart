import 'package:billetudo/core/database/app_database.dart' as db;
import 'package:billetudo/features/settings/data/datasources/app_settings_local_datasource.dart';
import 'package:billetudo/features/settings/data/repositories/app_settings_repository_impl.dart';
import 'package:billetudo/features/settings/domain/entities/app_settings.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

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

  group('watchSettings', () {
    test('emits AppSettings.defaults() when the singleton row is missing',
        () async {
      final result = await repository.watchSettings().first;

      expect(
        result.getRight().toNullable(),
        const AppSettings.defaults(),
      );
    });

    test('emits the persisted flag once it has been set', () async {
      await repository.setZeroBasedEnabled(enabled: true);

      final result = await repository.watchSettings().first;

      expect(result.getRight().toNullable()!.zeroBasedEnabled, isTrue);
    });

    test('re-emits when the flag is toggled again', () async {
      final values = <bool>[];
      final subscription = repository.watchSettings().listen((result) {
        values.add(result.getRight().toNullable()!.zeroBasedEnabled);
      });
      // Let the initial "missing row" emission land before the first write,
      // so it is not coalesced with it (Drift batches invalidations that
      // land in the same microtask).
      await Future<void>.delayed(Duration.zero);

      await repository.setZeroBasedEnabled(enabled: true);
      await Future<void>.delayed(Duration.zero);
      await repository.setZeroBasedEnabled(enabled: false);
      await Future<void>.delayed(Duration.zero);
      await subscription.cancel();

      expect(values, [false, true, false]);
    });
  });

  group('setZeroBasedEnabled', () {
    test('upserts the singleton row instead of creating a second one',
        () async {
      await repository.setZeroBasedEnabled(enabled: true);
      await repository.setZeroBasedEnabled(enabled: false);

      final rows = await database.select(database.appSettings).get();

      expect(rows, hasLength(1));
      expect(rows.single.id, AppSettingsLocalDatasource.singletonId);
      expect(rows.single.zeroBasedEnabled, isFalse);
    });

    test('stamps updatedAt on every write', () async {
      await repository.setZeroBasedEnabled(enabled: true);
      final first = await database.select(database.appSettings).getSingle();

      await Future<void>.delayed(const Duration(milliseconds: 5));
      await repository.setZeroBasedEnabled(enabled: false);
      final second = await database.select(database.appSettings).getSingle();

      expect(second.updatedAt, greaterThan(first.updatedAt));
    });
  });
}
