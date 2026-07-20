import 'dart:io';

import 'package:billetudo/core/database/app_database.dart';
import 'package:billetudo/core/database/database_connection.dart';
import 'package:billetudo/core/error/result.dart';
import 'package:billetudo/features/auth/data/datasources/local_data_wipe_datasource.dart';
import 'package:billetudo/features/categories/domain/repositories/category_repository.dart';
import 'package:billetudo/features/categories/domain/usecases/seed_default_categories.dart';
import 'package:billetudo/features/settings/data/datasources/app_settings_local_datasource.dart';
import 'package:billetudo/features/settings/data/repositories/app_settings_repository_impl.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:path/path.dart' as p;
import 'package:powersync/powersync.dart' show PowerSyncDatabase;

class MockCategoryRepository extends Mock implements CategoryRepository {}

/// Que pasa con el singleton `app_settings` **despues** del wipe de HU-06.
///
/// El wipe viejo (fila por fila con Drift) ni siquiera tocaba `app_settings`,
/// asi que la fila sobrevivia y cualquier `UPDATE` posterior funcionaba. El
/// wipe nuevo (`PowerSyncDatabase.disconnectAndClear` -> `powersync_clear`)
/// vacia **todas** las tablas sincronizadas, incluida esta, y ninguna
/// migracion vuelve a correr despues. Si `AppSettingsLocalDatasource` no se
/// auto-sanara (UPDATE y, si afecta 0 filas, INSERT), el latch
/// `categoriesSeeded` no se podria volver a poner nunca y las categorias por
/// defecto se re-sembrarian en cada arranque.
///
/// Corre sobre PowerSync real, no `NativeDatabase`: aqui `app_settings` es una
/// vista, y es la vista la que hace que un `INSERT ... ON CONFLICT DO UPDATE`
/// (el upsert obvio) sea ilegal en SQLite.
void main() {
  late Directory tempDir;
  late PowerSyncDatabase powerSync;
  late AppDatabase db;
  late AppSettingsLocalDatasource local;
  late AppSettingsRepositoryImpl settingsRepository;
  late LocalDataWipeDatasource wipe;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('app_settings_after_wipe');
    powerSync = await openPowerSyncDatabase(
      path: p.join(tempDir.path, 'test.sqlite'),
    );
    db = AppDatabase(driftConnection(powerSync));
    local = AppSettingsLocalDatasource(db);
    settingsRepository = AppSettingsRepositoryImpl(local);
    wipe = LocalDataWipeDatasource(powerSync);
  });

  tearDown(() async {
    await db.close();
    await powerSync.close();
    await tempDir.delete(recursive: true);
  });

  Future<int> settingsRows() async {
    final rows = await powerSync.getAll('SELECT id FROM app_settings');
    return rows.length;
  }

  group('el wipe se lleva app_settings', () {
    test('la fila singleton desaparece (powersync_clear no la perdona)',
        () async {
      await settingsRepository.setZeroBasedEnabled(enabled: true);
      expect(await settingsRows(), 1);

      await wipe.wipeAll();

      expect(
        await settingsRows(),
        0,
        reason: 'si esta fila sobreviviera, el resto de este archivo estaria '
            'probando el caso facil y no el real',
      );
    });
  });

  group('AppSettingsLocalDatasource se auto-sana despues del wipe', () {
    test('setZeroBasedEnabled persiste de verdad (recrea la fila)', () async {
      await wipe.wipeAll();

      await settingsRepository.setZeroBasedEnabled(enabled: true);

      final settings = await settingsRepository.getSettings();
      expect(settings.getRight().toNullable()!.zeroBasedEnabled, isTrue);
      expect(await settingsRows(), 1);
    });

    test('markCategoriesSeeded persiste de verdad (recrea la fila)', () async {
      await wipe.wipeAll();

      await settingsRepository.markCategoriesSeeded();

      final settings = await settingsRepository.getSettings();
      expect(settings.getRight().toNullable()!.categoriesSeeded, isTrue);
    });

    test('no crea una segunda fila al escribir dos veces seguidas', () async {
      await wipe.wipeAll();

      await settingsRepository.markCategoriesSeeded();
      await settingsRepository.setZeroBasedEnabled(enabled: true);

      expect(
        await settingsRows(),
        1,
        reason: 'app_settings es un singleton con id constante "app"',
      );
      final settings =
          (await settingsRepository.getSettings()).getRight().toNullable()!;
      expect(settings.categoriesSeeded, isTrue);
      expect(settings.zeroBasedEnabled, isTrue);
    });

    test('la escritura estampa updatedAt (PowerSync mergea last-write-wins)',
        () async {
      await wipe.wipeAll();
      final before = DateTime.now().millisecondsSinceEpoch;

      await settingsRepository.markCategoriesSeeded();

      final row = await local.readSettings();
      expect(row!.updatedAt, greaterThanOrEqualTo(before));
    });
  });

  group('SeedDefaultCategories despues del wipe', () {
    late MockCategoryRepository categories;
    late SeedDefaultCategories seed;

    setUp(() {
      categories = MockCategoryRepository();
      seed = SeedDefaultCategories(categories, settingsRepository);
      when(categories.hasAnyCategory).thenAnswer((_) async => const Right(false));
      when(categories.seedDefaultCategories)
          .thenAnswer((_) async => const Right(unit));
    });

    test('siembra una sola vez, no en cada arranque', () async {
      await wipe.wipeAll();

      final first = await seed();
      final second = await seed();
      final third = await seed();

      expect(first, const Right<Failure, Unit>(unit));
      expect(second, const Right<Failure, Unit>(unit));
      expect(third, const Right<Failure, Unit>(unit));
      verify(categories.seedDefaultCategories).called(1);
    });

    test(
      'el latch sobrevive a reabrir la app: una instancia nueva de los '
      'datasources tampoco vuelve a sembrar',
      () async {
        await wipe.wipeAll();
        await seed();

        // Simula el siguiente arranque: mismos archivos, objetos nuevos.
        final freshRepository = AppSettingsRepositoryImpl(
          AppSettingsLocalDatasource(db),
        );
        await SeedDefaultCategories(categories, freshRepository)();

        verify(categories.seedDefaultCategories).called(1);
      },
    );
  });
}
