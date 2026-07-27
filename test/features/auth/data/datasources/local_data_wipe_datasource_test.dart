import 'dart:io';

import 'package:billetudo/core/database/app_database.dart';
import 'package:billetudo/core/database/database_connection.dart';
import 'package:billetudo/features/auth/data/datasources/local_data_wipe_datasource.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:powersync/powersync.dart' show PowerSyncDatabase;

void main() {
  // Deliberately a real `PowerSyncDatabase` (with Drift on top of it), not a
  // `NativeDatabase`: the whole point of this datasource is what happens to
  // PowerSync's upload queue, which only exists on the real views/triggers.
  // `PowerSyncDatabase` is a `base class` so it cannot be mocked anyway.
  late Directory tempDir;
  late PowerSyncDatabase powerSync;
  late AppDatabase db;
  late LocalDataWipeDatasource datasource;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp(
      'local_data_wipe_datasource_test',
    );
    powerSync = await openPowerSyncDatabase(
      path: p.join(tempDir.path, 'test.sqlite'),
    );
    db = AppDatabase(driftConnection(powerSync));
    datasource = LocalDataWipeDatasource(powerSync);
  });

  tearDown(() async {
    await db.close();
    await powerSync.close();
    await tempDir.delete(recursive: true);
  });

  Future<int> pendingUploads() async {
    final rows = await powerSync.getAll('SELECT id FROM ps_crud');
    return rows.length;
  }

  test('borra las filas locales de este dispositivo', () async {
    await db.into(db.accounts).insert(
          AccountsCompanion.insert(
              name: 'Cuenta', type: AccountType.bank, currency: 'COP'),
        );

    await datasource.wipeAll();

    expect(await db.select(db.accounts).get(), isEmpty);
  });

  test('no deja operaciones encoladas para subir a la nube (HU-06)', () async {
    await db.into(db.accounts).insert(
          AccountsCompanion.insert(
              name: 'Cuenta', type: AccountType.bank, currency: 'COP'),
        );
    expect(await pendingUploads(), greaterThan(0));

    await datasource.wipeAll();

    expect(
      await pendingUploads(),
      0,
      reason: 'un DELETE encolado se sube al volver a entrar y borra la nube',
    );
  });
}
