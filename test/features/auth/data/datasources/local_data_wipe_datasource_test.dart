import 'dart:io';

import 'package:billetudo/core/crash/crash_reporter.dart';
import 'package:billetudo/core/database/app_database.dart';
import 'package:billetudo/core/database/database_connection.dart';
import 'package:billetudo/core/error/result.dart';
import 'package:billetudo/core/sync/data/models/sync_retry_record.dart';
import 'package:billetudo/core/sync/domain/repositories/sync_log_repository.dart';
import 'package:billetudo/core/sync/domain/repositories/sync_quarantine_repository.dart';
import 'package:billetudo/features/auth/data/datasources/local_data_wipe_datasource.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:path/path.dart' as p;
import 'package:powersync/powersync.dart' show PowerSyncDatabase;

import '../../../../support/fake_sync_retry_ledger_store.dart';

class MockCrashReporter extends Mock implements CrashReporter {}

class MockSyncQuarantineRepository extends Mock
    implements SyncQuarantineRepository {}

class MockSyncLogRepository extends Mock implements SyncLogRepository {}

void main() {
  setUpAll(() {
    registerFallbackValue(const DatabaseFailure('fallback'));
  });

  // Deliberately a real `PowerSyncDatabase` (with Drift on top of it), not a
  // `NativeDatabase`: the whole point of this datasource is what happens to
  // PowerSync's upload queue, which only exists on the real views/triggers.
  // `PowerSyncDatabase` is a `base class` so it cannot be mocked anyway.
  late Directory tempDir;
  late PowerSyncDatabase powerSync;
  late AppDatabase db;
  late MockSyncQuarantineRepository quarantine;
  late FakeSyncRetryLedgerStore retryLedger;
  late MockSyncLogRepository log;
  late MockCrashReporter crashReporter;
  late LocalDataWipeDatasource datasource;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp(
      'local_data_wipe_datasource_test',
    );
    powerSync = await openPowerSyncDatabase(
      path: p.join(tempDir.path, 'test.sqlite'),
    );
    db = AppDatabase(driftConnection(powerSync));
    quarantine = MockSyncQuarantineRepository();
    retryLedger = FakeSyncRetryLedgerStore();
    log = MockSyncLogRepository();
    crashReporter = MockCrashReporter();
    when(() => quarantine.clearAll())
        .thenAnswer((_) async => const Right(unit));
    when(() => log.clear()).thenAnswer((_) async => const Right(unit));
    when(
      () => crashReporter.recordFailure(any(), context: any(named: 'context')),
    ).thenAnswer((_) async {});
    when(
      () => crashReporter.recordError(
        any(),
        any(),
        context: any(named: 'context'),
        fatal: any(named: 'fatal'),
      ),
    ).thenAnswer((_) async {});
    datasource = LocalDataWipeDatasource(
      powerSync,
      quarantine,
      retryLedger,
      log,
      crashReporter,
    );
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

  test('también limpia la cuarentena de sync', () async {
    await datasource.wipeAll();

    verify(() => quarantine.clearAll()).called(1);
  });

  test('también limpia el ledger de reintentos de sync', () async {
    final now = DateTime(2026, 8, 21);
    retryLedger.seed(
      SyncRetryRecord(
        key: 'accounts#abc#patch',
        attempts: 3,
        firstFailureAt: now,
        lastFailureAt: now,
      ),
    );

    await datasource.wipeAll();

    expect(retryLedger.records, isEmpty);
  });

  test('también limpia el log local de sync', () async {
    await datasource.wipeAll();

    verify(() => log.clear()).called(1);
  });

  test(
    'no lanza y reporta al crash reporter si limpiar la cuarentena falla',
    () async {
      const failure = DatabaseFailure('boom');
      when(() => quarantine.clearAll())
          .thenAnswer((_) async => const Left(failure));

      await datasource.wipeAll();

      verify(
        () => crashReporter.recordFailure(failure,
            context: any(named: 'context')),
      ).called(1);
    },
  );

  test(
    'no lanza y reporta al crash reporter si limpiar el ledger de reintentos falla',
    () async {
      retryLedger.removeAllError = Exception('boom');

      await datasource.wipeAll();

      verify(
        () => crashReporter.recordError(
          any(),
          any(),
          context: any(named: 'context'),
        ),
      ).called(1);
    },
  );
}
