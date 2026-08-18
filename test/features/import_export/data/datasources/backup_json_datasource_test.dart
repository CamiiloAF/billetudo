import 'dart:convert';
import 'dart:io';

import 'package:billetudo/core/database/app_database.dart';
import 'package:billetudo/core/database/database_connection.dart';
import 'package:billetudo/features/import_export/data/datasources/backup_json_datasource.dart';
import 'package:billetudo/features/import_export/domain/entities/cancellation_token.dart';
import 'package:billetudo/features/import_export/domain/entities/restore_mode.dart';
import 'package:drift/drift.dart' show Value, driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

void main() {
  late Directory tempDir;
  late AppDatabase sourceDb;
  late BackupJsonDatasource sourceDatasource;

  setUp(() {
    tempDir = Directory.systemTemp.createTempSync('billetudo_backup_test');
    sourceDb = AppDatabase(NativeDatabase.memory());
    sourceDatasource = BackupJsonDatasource(sourceDb);
  });

  tearDown(() async {
    await sourceDb.close();
    if (tempDir.existsSync()) {
      tempDir.deleteSync(recursive: true);
    }
  });

  test('createFullBackup escribe una cabecera versionada y cuenta las filas',
      () async {
    await sourceDb.into(sourceDb.accounts).insert(
          AccountsCompanion.insert(name: 'Efectivo', type: AccountType.cash, currency: 'COP'),
        );
    final path = p.join(tempDir.path, 'copia.billetudo.json');

    final result = await sourceDatasource.createFullBackup(path);

    final header = result.getRight().toNullable()!;
    expect(header['formatVersion'], backupFormatVersion);
    expect(header['schemaVersion'], sourceDb.schemaVersion);
    expect((header['rowCountsByTable'] as Map)['accounts'], 1);
    expect(File(path).existsSync(), isTrue);
  });

  test('parseHeader lee la cabecera sin escribir ninguna tabla', () async {
    await sourceDb.into(sourceDb.accounts).insert(
          AccountsCompanion.insert(name: 'Efectivo', type: AccountType.cash, currency: 'COP'),
        );
    final path = p.join(tempDir.path, 'copia.billetudo.json');
    await sourceDatasource.createFullBackup(path);

    final result = await sourceDatasource.parseHeader(path);

    final header = result.getRight().toNullable()!;
    expect(header['formatVersion'], backupFormatVersion);
  });

  test('createFullBackup reporta progreso creciente, tabla por tabla',
      () async {
    await sourceDb.into(sourceDb.accounts).insert(
          AccountsCompanion.insert(name: 'Efectivo', type: AccountType.cash, currency: 'COP'),
        );
    final path = p.join(tempDir.path, 'copia.billetudo.json');
    final calls = <(int, int?)>[];

    await sourceDatasource.createFullBackup(
      path,
      onProgress: (processed, total) => calls.add((processed, total)),
    );

    expect(calls, isNotEmpty);
    expect(calls.first.$1, 0);
    expect(calls.last.$1, backupTableNames.length);
    for (var i = 1; i < calls.length; i++) {
      expect(calls[i].$1, greaterThan(calls[i - 1].$1));
    }
  });

  test('createFullBackup cancelado borra el archivo parcial', () async {
    final path = p.join(tempDir.path, 'copia.billetudo.json');
    final token = CancellationToken();

    final result = await sourceDatasource.createFullBackup(
      path,
      onProgress: (processed, total) {
        // Cancels right after the first table is written.
        if (processed == 1) {
          token.cancel();
        }
      },
      cancellationToken: token,
    );

    expect(result.isLeft(), isTrue);
    expect(File(path).existsSync(), isFalse);
  });

  test('un archivo vacío falla con IoFailure, no con una excepción cruda',
      () async {
    final path = p.join(tempDir.path, 'vacio.json');
    File(path).writeAsStringSync('');

    final result = await sourceDatasource.parseHeader(path);

    expect(result.isLeft(), isTrue);
  });

  test(
    'HU-03: la copia completa nunca incluye userId (columna de sync, no del '
    'usuario) — `docs/requirements/fase-1/11-import-export.md` §Identidad y datos '
    'que nunca salen',
    () async {
      await sourceDb.into(sourceDb.accounts).insert(
            AccountsCompanion.insert(
              name: 'Efectivo',
              type: AccountType.cash,
              currency: 'COP',
              userId: const Value('user-abc-123'),
            ),
          );
      final path = p.join(tempDir.path, 'copia.billetudo.json');

      await sourceDatasource.createFullBackup(path);

      final decoded = jsonDecode(await File(path).readAsString()) as Map;
      final accountRows = (decoded['tables'] as Map)['accounts'] as List;
      final accountJson = accountRows.single as Map;
      expect(
        accountJson.containsKey('userId'),
        isFalse,
        reason: 'the unencrypted .billetudo.json copy must never carry '
            'userId — it is a sync-only column, not user data, and this '
            'copy can be shared/backed up outside the app\'s control',
      );
    },
  );

  group('restore — HU-04', () {
    test('modo fusionar: una fila que no existe se crea', () async {
      await sourceDb.into(sourceDb.accounts).insert(
            AccountsCompanion.insert(
              name: 'Efectivo',
              type: AccountType.cash,
              currency: 'COP',
            ),
          );
      final path = p.join(tempDir.path, 'copia.billetudo.json');
      await sourceDatasource.createFullBackup(path);

      final targetDb = AppDatabase(NativeDatabase.memory());
      final targetDatasource = BackupJsonDatasource(targetDb);
      addTearDown(targetDb.close);

      final result = await targetDatasource.restore(path, mode: RestoreMode.merge);

      final byTable = result.getRight().toNullable()!;
      expect(byTable['accounts']!.created, 1);
      final accounts = await targetDb.select(targetDb.accounts).get();
      expect(accounts, hasLength(1));
      expect(accounts.single.name, 'Efectivo');
    });

    test('modo fusionar: gana la fila con updatedAt mayor (last-write-wins)',
        () async {
      final now = DateTime.now().millisecondsSinceEpoch;
      const id = 'shared-id';

      final targetDb = AppDatabase(NativeDatabase.memory());
      final targetDatasource = BackupJsonDatasource(targetDb);
      addTearDown(targetDb.close);
      await targetDb.into(targetDb.accounts).insert(
            AccountsCompanion.insert(
              id: Value(id),
              name: 'Nombre local (más nuevo)',
              type: AccountType.cash,
              currency: 'COP',
              updatedAt: Value(now + 10000),
            ),
          );

      await sourceDb.into(sourceDb.accounts).insert(
            AccountsCompanion.insert(
              id: Value(id),
              name: 'Nombre de la copia (más viejo)',
              type: AccountType.cash,
              currency: 'COP',
              updatedAt: Value(now),
            ),
          );
      final path = p.join(tempDir.path, 'copia.billetudo.json');
      await sourceDatasource.createFullBackup(path);

      final result = await targetDatasource.restore(path, mode: RestoreMode.merge);

      final byTable = result.getRight().toNullable()!;
      expect(byTable['accounts']!.skipped, 1);
      final accounts = await targetDb.select(targetDb.accounts).get();
      expect(accounts.single.name, 'Nombre local (más nuevo)');
    });

    test('modo reemplazar todo: borra lo local y deja solo el contenido de la copia',
        () async {
      final targetDb = AppDatabase(NativeDatabase.memory());
      final targetDatasource = BackupJsonDatasource(targetDb);
      addTearDown(targetDb.close);
      await targetDb.into(targetDb.accounts).insert(
            AccountsCompanion.insert(
              name: 'Solo en el dispositivo',
              type: AccountType.cash,
              currency: 'COP',
            ),
          );

      await sourceDb.into(sourceDb.accounts).insert(
            AccountsCompanion.insert(
              name: 'De la copia',
              type: AccountType.cash,
              currency: 'COP',
            ),
          );
      final path = p.join(tempDir.path, 'copia.billetudo.json');
      await sourceDatasource.createFullBackup(path);

      await targetDatasource.restore(path, mode: RestoreMode.replaceAll);

      final accounts = await targetDb.select(targetDb.accounts).get();
      expect(accounts, hasLength(1));
      expect(accounts.single.name, 'De la copia');
    });

    test(
        'modo reemplazar todo: una transacción se restaura junto con la '
        'cuenta que referencia, en una base vacía', () async {
      // Regression: restore() used to reuse `backupTableNames` (children
      // before parents — correct for the delete pass, wrong for insert) to
      // insert rows too, so `transactions` was merged before `accounts`. On
      // a database with nothing local — exactly what "reemplazar todo"
      // leaves right before this insert pass runs — inserting a transaction
      // whose `accountId` doesn't exist yet violates the FK and the whole
      // restore fails.
      const accountId = 'acc-1';
      await sourceDb.into(sourceDb.accounts).insert(
            AccountsCompanion.insert(
              id: Value(accountId),
              name: 'Nequi',
              type: AccountType.cash,
              currency: 'COP',
            ),
          );
      await sourceDb.into(sourceDb.transactions).insert(
            TransactionsCompanion.insert(
              accountId: accountId,
              amountMinor: 5000,
              currency: 'COP',
              type: EntryType.expense,
              date: DateTime(2026, 1, 1),
            ),
          );
      final path = p.join(tempDir.path, 'copia.billetudo.json');
      await sourceDatasource.createFullBackup(path);

      final targetDb = AppDatabase(NativeDatabase.memory());
      final targetDatasource = BackupJsonDatasource(targetDb);
      addTearDown(targetDb.close);

      final result = await targetDatasource.restore(path, mode: RestoreMode.replaceAll);

      expect(result.isRight(), isTrue, reason: '${result.getLeft().toNullable()}');
      final accounts = await targetDb.select(targetDb.accounts).get();
      final transactions = await targetDb.select(targetDb.transactions).get();
      expect(accounts, hasLength(1));
      expect(transactions, hasLength(1));
      expect(transactions.single.accountId, accountId);
    });

    test('cancelar a medio restaurar no deja ninguna tabla mezclada (rollback)',
        () async {
      await sourceDb.into(sourceDb.accounts).insert(
            AccountsCompanion.insert(
              name: 'De la copia',
              type: AccountType.cash,
              currency: 'COP',
            ),
          );
      final path = p.join(tempDir.path, 'copia.billetudo.json');
      await sourceDatasource.createFullBackup(path);

      final targetDb = AppDatabase(NativeDatabase.memory());
      final targetDatasource = BackupJsonDatasource(targetDb);
      addTearDown(targetDb.close);
      final token = CancellationToken();
      final accountsIndex = restoreInsertOrder.indexOf('accounts');

      final result = await targetDatasource.restore(
        path,
        mode: RestoreMode.merge,
        onProgress: (processed, total) {
          // Cancels right *after* the `accounts` table would have been
          // merged, so the assertion below proves the whole transaction
          // rolled back — not merely that later tables were skipped.
          if (processed == accountsIndex + 1) {
            token.cancel();
          }
        },
        cancellationToken: token,
      );

      expect(result.isLeft(), isTrue);
      final accounts = await targetDb.select(targetDb.accounts).get();
      expect(accounts, isEmpty);
    });
  });

  group('restore — HU-04, contra una base real respaldada por PowerSync', () {
    // Regression: every other test in this file uses `AppDatabase(
    // NativeDatabase.memory())` — plain SQLite, real tables. Production
    // opens `AppDatabase` on top of a `PowerSyncDatabase` connection
    // instead (decision #6, `05-auth-sync.md`): every synced table there is
    // actually a VIEW with `INSTEAD OF` triggers, not a real table. SQLite
    // refuses to run an UPSERT (`INSERT ... ON CONFLICT DO UPDATE`, what
    // `insertOnConflictUpdate` generates) against a view — "cannot UPSERT a
    // view" — a restriction plain-SQLite tests can never see. This caused a
    // 100%-reproducible failure on every real restore, in both modes, that
    // 19 passing tests above never caught. `_insertRow` now uses
    // `InsertMode.insertOrReplace` (the older, trigger-compatible syntax)
    // instead — these tests open a real `PowerSyncDatabase` to prove it.
    late Directory powerSyncTempDir;

    setUpAll(() {
      driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
    });

    setUp(() {
      powerSyncTempDir = Directory.systemTemp.createTempSync('billetudo_ps_backup_test');
    });

    tearDown(() {
      if (powerSyncTempDir.existsSync()) {
        powerSyncTempDir.deleteSync(recursive: true);
      }
    });

    Future<AppDatabase> openPowerSyncBackedDb(String fileName) async {
      final powerSyncDb = await openPowerSyncDatabase(
        path: p.join(powerSyncTempDir.path, fileName),
      );
      return AppDatabase(driftConnection(powerSyncDb));
    }

    test(
        'modo reemplazar todo: cuenta + transacción se restauran en una base '
        'vacía sin lanzar "cannot UPSERT a view"', () async {
      final realSourceDb = await openPowerSyncBackedDb('source.sqlite');
      final realSourceDatasource = BackupJsonDatasource(realSourceDb);
      addTearDown(realSourceDb.close);

      const accountId = 'acc-1';
      const categoryId = 'cat-1';
      await realSourceDb.into(realSourceDb.accounts).insert(
            AccountsCompanion.insert(
              id: const Value(accountId),
              name: 'Nequi',
              type: AccountType.cash,
              currency: 'COP',
            ),
          );
      await realSourceDb.into(realSourceDb.categories).insert(
            CategoriesCompanion.insert(
              id: const Value(categoryId),
              name: 'Comida y bebidas',
              kind: CategoryKind.expense,
            ),
          );
      await realSourceDb.into(realSourceDb.transactions).insert(
            TransactionsCompanion.insert(
              accountId: accountId,
              categoryId: const Value(categoryId),
              amountMinor: 5000,
              currency: 'COP',
              type: EntryType.expense,
              date: DateTime(2026, 1, 1),
            ),
          );
      final path = p.join(powerSyncTempDir.path, 'copia.billetudo.json');
      await realSourceDatasource.createFullBackup(path);

      final realTargetDb = await openPowerSyncBackedDb('target.sqlite');
      final realTargetDatasource = BackupJsonDatasource(realTargetDb);
      addTearDown(realTargetDb.close);

      final result = await realTargetDatasource.restore(path, mode: RestoreMode.replaceAll);

      expect(result.isRight(), isTrue, reason: '${result.getLeft().toNullable()}');
      final accounts = await realTargetDb.select(realTargetDb.accounts).get();
      final categories = await realTargetDb.select(realTargetDb.categories).get();
      final transactions = await realTargetDb.select(realTargetDb.transactions).get();
      expect(accounts, hasLength(1));
      expect(categories, hasLength(1));
      expect(transactions, hasLength(1));
    });

    test(
        'modo fusionar: una fila existente se actualiza sin lanzar '
        '"cannot UPSERT a view"', () async {
      const accountId = 'acc-1';
      final now = DateTime.now().millisecondsSinceEpoch;

      final realTargetDb = await openPowerSyncBackedDb('target.sqlite');
      final realTargetDatasource = BackupJsonDatasource(realTargetDb);
      addTearDown(realTargetDb.close);
      await realTargetDb.into(realTargetDb.accounts).insert(
            AccountsCompanion.insert(
              id: const Value(accountId),
              name: 'Nombre viejo',
              type: AccountType.cash,
              currency: 'COP',
              updatedAt: Value(now),
            ),
          );

      final realSourceDb = await openPowerSyncBackedDb('source.sqlite');
      final realSourceDatasource = BackupJsonDatasource(realSourceDb);
      addTearDown(realSourceDb.close);
      await realSourceDb.into(realSourceDb.accounts).insert(
            AccountsCompanion.insert(
              id: const Value(accountId),
              name: 'Nombre nuevo',
              type: AccountType.cash,
              currency: 'COP',
              updatedAt: Value(now + 10000),
            ),
          );
      final path = p.join(powerSyncTempDir.path, 'copia.billetudo.json');
      await realSourceDatasource.createFullBackup(path);

      final result = await realTargetDatasource.restore(path, mode: RestoreMode.merge);

      expect(result.isRight(), isTrue, reason: '${result.getLeft().toNullable()}');
      final accounts = await realTargetDb.select(realTargetDb.accounts).get();
      expect(accounts.single.name, 'Nombre nuevo');
    });
  });
}
