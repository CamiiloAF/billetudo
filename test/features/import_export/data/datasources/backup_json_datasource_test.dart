import 'dart:convert';
import 'dart:io';

import 'package:billetudo/core/database/app_database.dart';
import 'package:billetudo/core/database/database_connection.dart';
import 'package:billetudo/core/error/result.dart';
import 'package:billetudo/core/sync/data/datasources/backup_id_collision_datasource.dart';
import 'package:billetudo/core/sync/data/datasources/data_ownership_claimer.dart';
import 'package:billetudo/core/sync/domain/repositories/backup_id_collision_resolver.dart';
import 'package:billetudo/features/auth/data/datasources/local_data_ownership_datasource.dart';
import 'package:billetudo/features/auth/data/datasources/seed_category_ownership_remote_datasource.dart';
import 'package:billetudo/features/import_export/data/datasources/backup_json_datasource.dart';
import 'package:billetudo/features/import_export/domain/entities/cancellation_token.dart';
import 'package:billetudo/features/import_export/domain/entities/restore_mode.dart';
import 'package:billetudo/features/import_export/domain/usecases/resolve_backup_id_conflicts.dart';
import 'package:drift/drift.dart' show Value, driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:mocktail/mocktail.dart';
import 'package:path/path.dart' as p;
import 'package:supabase_flutter/supabase_flutter.dart';

class MockDataOwnershipClaimer extends Mock implements DataOwnershipClaimer {}

class MockSeedCategoryOwnershipRemoteDatasource extends Mock
    implements SeedCategoryOwnershipRemoteDatasource {}

class MockBackupIdCollisionResolver extends Mock
    implements BackupIdCollisionResolver {}

class MockBackupIdCollisionDatasource extends Mock
    implements BackupIdCollisionDatasource {}

/// A Supabase session that never hits the network: `setInitialSession` only
/// deserializes it, and the far-future expiry avoids any refresh call — the
/// same pattern used in `supabase_operation_uploader_test.dart`.
String _sessionJson(String userId) => jsonEncode({
      'access_token': 'jwt-for-$userId',
      'token_type': 'bearer',
      'expires_in': 3600,
      'expires_at':
          DateTime.now().add(const Duration(hours: 1)).millisecondsSinceEpoch ~/
              1000,
      'refresh_token': 'refresh-token',
      'user': {
        'id': userId,
        'app_metadata': <String, dynamic>{},
        'user_metadata': <String, dynamic>{},
        'aud': 'authenticated',
        'created_at': '2026-01-01T00:00:00Z',
      },
    });

void main() {
  late Directory tempDir;
  late AppDatabase sourceDb;
  late BackupJsonDatasource sourceDatasource;
  late MockDataOwnershipClaimer ownership;
  late MockBackupIdCollisionResolver collisionResolver;
  late SupabaseClient noSessionSupabase;

  /// [BackupJsonDatasource] always needs a [DataOwnershipClaimer], a
  /// [SupabaseClient] and a [ResolveBackupIdConflicts] now — most tests
  /// below don't exercise the ownership claim or the id-collision remap at
  /// all (no active session), so they share one no-op claimer, one
  /// never-colliding resolver and one signed-out client via this helper
  /// instead of repeating the wiring.
  BackupJsonDatasource buildDatasource(AppDatabase database) =>
      BackupJsonDatasource(
        database,
        ownership,
        noSessionSupabase,
        ResolveBackupIdConflicts(collisionResolver),
      );

  setUp(() {
    tempDir = Directory.systemTemp.createTempSync('billetudo_backup_test');
    sourceDb = AppDatabase(NativeDatabase.memory());
    ownership = MockDataOwnershipClaimer();
    collisionResolver = MockBackupIdCollisionResolver();
    when(() => collisionResolver.findCollidingIds(
          userId: any(named: 'userId'),
          idsByTable: any(named: 'idsByTable'),
        )).thenAnswer((_) async => const Right({}));
    noSessionSupabase = SupabaseClient(
      'https://example.supabase.co',
      'anon-key',
      httpClient: MockClient(
        (request) async => http.Response('', 200, request: request),
      ),
    );
    addTearDown(noSessionSupabase.dispose);
    sourceDatasource = buildDatasource(sourceDb);
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
          AccountsCompanion.insert(
              name: 'Efectivo', type: AccountType.cash, currency: 'COP'),
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
          AccountsCompanion.insert(
              name: 'Efectivo', type: AccountType.cash, currency: 'COP'),
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
          AccountsCompanion.insert(
              name: 'Efectivo', type: AccountType.cash, currency: 'COP'),
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
      final targetDatasource = buildDatasource(targetDb);
      addTearDown(targetDb.close);

      final result =
          await targetDatasource.restore(path, mode: RestoreMode.merge);

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
      final targetDatasource = buildDatasource(targetDb);
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

      final result =
          await targetDatasource.restore(path, mode: RestoreMode.merge);

      final byTable = result.getRight().toNullable()!;
      expect(byTable['accounts']!.skipped, 1);
      final accounts = await targetDb.select(targetDb.accounts).get();
      expect(accounts.single.name, 'Nombre local (más nuevo)');
    });

    test(
        'modo reemplazar todo: borra lo local y deja solo el contenido de la copia',
        () async {
      final targetDb = AppDatabase(NativeDatabase.memory());
      final targetDatasource = buildDatasource(targetDb);
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
      final targetDatasource = buildDatasource(targetDb);
      addTearDown(targetDb.close);

      final result =
          await targetDatasource.restore(path, mode: RestoreMode.replaceAll);

      expect(result.isRight(), isTrue,
          reason: '${result.getLeft().toNullable()}');
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
      final targetDatasource = buildDatasource(targetDb);
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
      powerSyncTempDir =
          Directory.systemTemp.createTempSync('billetudo_ps_backup_test');
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
      final realSourceDatasource = buildDatasource(realSourceDb);
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
      final realTargetDatasource = buildDatasource(realTargetDb);
      addTearDown(realTargetDb.close);

      final result = await realTargetDatasource.restore(path,
          mode: RestoreMode.replaceAll);

      expect(result.isRight(), isTrue,
          reason: '${result.getLeft().toNullable()}');
      final accounts = await realTargetDb.select(realTargetDb.accounts).get();
      final categories =
          await realTargetDb.select(realTargetDb.categories).get();
      final transactions =
          await realTargetDb.select(realTargetDb.transactions).get();
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
      final realTargetDatasource = buildDatasource(realTargetDb);
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
      final realSourceDatasource = buildDatasource(realSourceDb);
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

      final result =
          await realTargetDatasource.restore(path, mode: RestoreMode.merge);

      expect(result.isRight(), isTrue,
          reason: '${result.getLeft().toNullable()}');
      final accounts = await realTargetDb.select(realTargetDb.accounts).get();
      expect(accounts.single.name, 'Nombre nuevo');
    });
  });

  group('restore — orden topológico de categorías', () {
    test(
        'una subcategoría listada antes que su padre en el backup igual se '
        'inserta después de él (padre primero)', () async {
      const parentId = 'parent-1';
      const childId = 'child-1';
      // Inserted child-first so the source DB's natural row order — and
      // therefore the backup JSON's order, since `_readTableAsJson` has no
      // `ORDER BY` — really is child-before-parent.
      await sourceDb.into(sourceDb.categories).insert(
            CategoriesCompanion.insert(
              id: const Value(childId),
              name: 'Restaurantes',
              kind: CategoryKind.expense,
              parentId: const Value(parentId),
            ),
          );
      await sourceDb.into(sourceDb.categories).insert(
            CategoriesCompanion.insert(
              id: const Value(parentId),
              name: 'Comida y bebidas',
              kind: CategoryKind.expense,
            ),
          );
      final path = p.join(tempDir.path, 'copia.billetudo.json');
      await sourceDatasource.createFullBackup(path);

      final decoded = jsonDecode(await File(path).readAsString()) as Map;
      final categoryRows = (decoded['tables'] as Map)['categories'] as List;
      expect(
        (categoryRows.first as Map)['id'],
        childId,
        reason: 'the backup itself must list the child before the parent, '
            'or this test proves nothing',
      );

      final targetDb = AppDatabase(NativeDatabase.memory());
      final targetDatasource = buildDatasource(targetDb);
      addTearDown(targetDb.close);

      final result =
          await targetDatasource.restore(path, mode: RestoreMode.merge);

      expect(result.isRight(), isTrue,
          reason: '${result.getLeft().toNullable()}');
      // `rowid` reflects real physical insertion order in SQLite — this is
      // what proves the parent was actually inserted (and thus queued for
      // PowerSync upload) before its child, not just that both ended up in
      // the table somehow.
      final insertedOrder = await targetDb
          .customSelect('SELECT id FROM categories ORDER BY rowid')
          .get();
      final ids = insertedOrder.map((row) => row.read<String>('id')).toList();
      expect(
        ids,
        [parentId, childId],
        reason: 'a child inserted (and so uploaded) before its parent makes '
            'Postgres reject it with a 23503 FK violation, which PowerSync '
            'quarantines permanently — see SyncErrorClassifier',
      );
    });

    test(
        'una referencia circular dentro del mismo lote no cuelga el restore '
        '(se inserta el resto en cualquier orden estable)', () async {
      const idA = 'cycle-a';
      const idB = 'cycle-b';
      // `parentId` FK is only enforced against Postgres, not locally (no
      // `PRAGMA foreign_keys` here), so plain SQLite happily stores this
      // already-corrupt pair — the topological sort must still terminate.
      await sourceDb.into(sourceDb.categories).insert(
            CategoriesCompanion.insert(
              id: const Value(idA),
              name: 'A',
              kind: CategoryKind.expense,
              parentId: const Value(idB),
            ),
          );
      await sourceDb.into(sourceDb.categories).insert(
            CategoriesCompanion.insert(
              id: const Value(idB),
              name: 'B',
              kind: CategoryKind.expense,
              parentId: const Value(idA),
            ),
          );
      final path = p.join(tempDir.path, 'copia.billetudo.json');
      await sourceDatasource.createFullBackup(path);

      final targetDb = AppDatabase(NativeDatabase.memory());
      final targetDatasource = buildDatasource(targetDb);
      addTearDown(targetDb.close);

      final result = await targetDatasource
          .restore(path, mode: RestoreMode.merge)
          .timeout(const Duration(seconds: 5));

      expect(result.isRight(), isTrue,
          reason: '${result.getLeft().toNullable()}');
      final categories = await targetDb.select(targetDb.categories).get();
      expect(categories, hasLength(2));
    });

    test(
        'un parentId que no está en el mismo lote (ej. ya existe en la base '
        'local) no bloquea la inserción', () async {
      const localParentId = 'already-local-parent';
      const importedChildId = 'imported-child';
      final targetDb = AppDatabase(NativeDatabase.memory());
      final targetDatasource = buildDatasource(targetDb);
      addTearDown(targetDb.close);
      await targetDb.into(targetDb.categories).insert(
            CategoriesCompanion.insert(
              id: const Value(localParentId),
              name: 'Ya existente localmente',
              kind: CategoryKind.expense,
            ),
          );

      await sourceDb.into(sourceDb.categories).insert(
            CategoriesCompanion.insert(
              id: const Value(importedChildId),
              name: 'Importada',
              kind: CategoryKind.expense,
              parentId: const Value(localParentId),
            ),
          );
      final path = p.join(tempDir.path, 'copia.billetudo.json');
      await sourceDatasource.createFullBackup(path);

      final result =
          await targetDatasource.restore(path, mode: RestoreMode.merge);

      expect(result.isRight(), isTrue,
          reason: '${result.getLeft().toNullable()}');
      final categories = await targetDb.select(targetDb.categories).get();
      expect(categories, hasLength(2));
    });

    test(
        'reemplazar todo borra categorías en orden hijo antes que padre '
        '(evita el 23503 de la FK compuesta de Postgres en una reimportación)',
        () async {
      const grandparentId = 'grandparent-1';
      const parentId = 'parent-1';
      const childId = 'child-1';
      final targetDb = AppDatabase(NativeDatabase.memory());
      final targetDatasource = buildDatasource(targetDb);
      addTearDown(targetDb.close);
      // Root first, on purpose: the bug this guards against comes from
      // SQLite's own row scan order during a mass `DELETE FROM categories`,
      // which has nothing to do with insertion order — inserting "right"
      // first makes sure the fix isn't accidentally relying on it either.
      await targetDb.into(targetDb.categories).insert(
            CategoriesCompanion.insert(
              id: const Value(grandparentId),
              name: 'Abuela',
              kind: CategoryKind.expense,
            ),
          );
      await targetDb.into(targetDb.categories).insert(
            CategoriesCompanion.insert(
              id: const Value(parentId),
              name: 'Padre',
              kind: CategoryKind.expense,
              parentId: const Value(grandparentId),
            ),
          );
      await targetDb.into(targetDb.categories).insert(
            CategoriesCompanion.insert(
              id: const Value(childId),
              name: 'Hijo',
              kind: CategoryKind.expense,
              parentId: const Value(parentId),
            ),
          );

      // A trigger-backed log is the only way to observe the *order* the
      // individual `DELETE FROM categories WHERE id = ?` statements ran in
      // — a mass `DELETE` gives no such guarantee once rows are gone.
      await targetDb.customStatement(
        'CREATE TABLE delete_log (seq INTEGER PRIMARY KEY AUTOINCREMENT, '
        'category_id TEXT)',
      );
      await targetDb.customStatement(
        'CREATE TRIGGER delete_log_trigger AFTER DELETE ON categories '
        'BEGIN INSERT INTO delete_log (category_id) VALUES (OLD.id); END',
      );

      // An empty backup is enough: `replaceAll`'s wipe pass runs
      // unconditionally, regardless of what (if anything) gets restored
      // afterwards.
      final path = p.join(tempDir.path, 'copia.billetudo.json');
      await sourceDatasource.createFullBackup(path);

      final result =
          await targetDatasource.restore(path, mode: RestoreMode.replaceAll);

      expect(result.isRight(), isTrue,
          reason: '${result.getLeft().toNullable()}');
      final log = await targetDb
          .customSelect('SELECT category_id FROM delete_log ORDER BY seq')
          .get();
      final deleteOrder =
          [for (final row in log) row.read<String>('category_id')];
      expect(
        deleteOrder,
        [childId, parentId, grandparentId],
        reason: 'deleting a parent before its child during a "reemplazar '
            'todo" wipe queues that parent\'s delete op for PowerSync '
            'upload first — Postgres still has the child pointing at it, '
            'so it rejects the parent delete with a 23503 FK violation, '
            'which SyncErrorClassifier quarantines permanently',
      );
    });
  });

  group('restore — userId (HU-04, mecanismo de reclamo tras un restore)', () {
    test('sin sesión activa, userId queda null tras el restore (como hoy)',
        () async {
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
      final targetDatasource = buildDatasource(targetDb);
      addTearDown(targetDb.close);

      final result =
          await targetDatasource.restore(path, mode: RestoreMode.merge);

      expect(result.isRight(), isTrue,
          reason: '${result.getLeft().toNullable()}');
      final account = await targetDb.select(targetDb.accounts).getSingle();
      expect(account.userId, isNull);
      verifyNever(() => ownership.claimUnownedRows(any()));
    });

    test(
        'con sesión activa, se reclama todo lo importado para el usuario '
        'actual', () async {
      final seedOwnership = MockSeedCategoryOwnershipRemoteDatasource();
      when(() => seedOwnership.existingSeedCategoryIds(any(), any()))
          .thenAnswer((_) async => const []);
      final targetDb = AppDatabase(NativeDatabase.memory());
      addTearDown(targetDb.close);
      final realOwnership = LocalDataOwnershipDatasource(
        targetDb,
        seedOwnership,
        MockBackupIdCollisionDatasource(),
      );
      final signedInSupabase = SupabaseClient(
        'https://example.supabase.co',
        'anon-key',
        httpClient: MockClient(
          (request) async => http.Response('', 200, request: request),
        ),
      );
      addTearDown(signedInSupabase.dispose);
      await signedInSupabase.auth.setInitialSession(_sessionJson('user-1'));
      final targetDatasource = BackupJsonDatasource(
        targetDb,
        realOwnership,
        signedInSupabase,
        ResolveBackupIdConflicts(collisionResolver),
      );

      await sourceDb.into(sourceDb.accounts).insert(
            AccountsCompanion.insert(
              name: 'Efectivo',
              type: AccountType.cash,
              currency: 'COP',
            ),
          );
      await sourceDb.into(sourceDb.categories).insert(
            CategoriesCompanion.insert(
              id: const Value('cat-1'),
              name: 'Comida y bebidas',
              kind: CategoryKind.expense,
            ),
          );
      final path = p.join(tempDir.path, 'copia.billetudo.json');
      await sourceDatasource.createFullBackup(path);

      final result =
          await targetDatasource.restore(path, mode: RestoreMode.merge);

      expect(result.isRight(), isTrue,
          reason: '${result.getLeft().toNullable()}');
      final account = await targetDb.select(targetDb.accounts).getSingle();
      final category = await targetDb.select(targetDb.categories).getSingle();
      expect(account.userId, 'user-1');
      expect(category.userId, 'user-1');
    });

    test(
        'respeta la excepción de categorías seed ya poseídas por la cuenta '
        '(decisión #12) — no las reclama', () async {
      final seedOwnership = MockSeedCategoryOwnershipRemoteDatasource();
      when(() => seedOwnership.existingSeedCategoryIds('user-1', any()))
          .thenAnswer((_) async => const ['seed-food-drink']);
      await sourceDb.into(sourceDb.categories).insert(
            CategoriesCompanion.insert(
              id: const Value('seed-food-drink'),
              name: 'Comida y bebidas',
              kind: CategoryKind.expense,
            ),
          );
      final path = p.join(tempDir.path, 'copia.billetudo.json');
      await sourceDatasource.createFullBackup(path);

      final targetDb = AppDatabase(NativeDatabase.memory());
      addTearDown(targetDb.close);
      final realOwnership = LocalDataOwnershipDatasource(
        targetDb,
        seedOwnership,
        MockBackupIdCollisionDatasource(),
      );
      final signedInSupabase = SupabaseClient(
        'https://example.supabase.co',
        'anon-key',
        httpClient: MockClient(
          (request) async => http.Response('', 200, request: request),
        ),
      );
      addTearDown(signedInSupabase.dispose);
      await signedInSupabase.auth.setInitialSession(_sessionJson('user-1'));
      final targetDatasource = BackupJsonDatasource(
        targetDb,
        realOwnership,
        signedInSupabase,
        ResolveBackupIdConflicts(collisionResolver),
      );

      final result =
          await targetDatasource.restore(path, mode: RestoreMode.merge);

      expect(result.isRight(), isTrue,
          reason: '${result.getLeft().toNullable()}');
      final category = await targetDb.select(targetDb.categories).getSingle();
      expect(
        category.userId,
        isNull,
        reason: 'a seed-* category the account already owns elsewhere must '
            'not be re-claimed by this device',
      );
    });
  });

  group('restore — colisión de ids entre cuentas Supabase distintas', () {
    /// A signed-in (`user-1`) `AppDatabase` + [BackupJsonDatasource] pair
    /// whose [DataOwnershipClaimer] is a no-op (these tests are about the
    /// id-collision remap, not the claim step) and whose id-collision
    /// resolver is [resolver] — so each test can stub exactly which ids
    /// collide.
    Future<(AppDatabase, BackupJsonDatasource)> buildSignedInTarget(
      MockBackupIdCollisionResolver resolver,
    ) async {
      final targetDb = AppDatabase(NativeDatabase.memory());
      addTearDown(targetDb.close);
      final noopOwnership = MockDataOwnershipClaimer();
      when(() => noopOwnership.claimUnownedRows(any()))
          .thenAnswer((_) async => const Right(unit));
      final signedInSupabase = SupabaseClient(
        'https://example.supabase.co',
        'anon-key',
        httpClient: MockClient(
          (request) async => http.Response('', 200, request: request),
        ),
      );
      addTearDown(signedInSupabase.dispose);
      await signedInSupabase.auth.setInitialSession(_sessionJson('user-1'));
      final targetDatasource = BackupJsonDatasource(
        targetDb,
        noopOwnership,
        signedInSupabase,
        ResolveBackupIdConflicts(resolver),
      );
      return (targetDb, targetDatasource);
    }

    test(
        'sin sesión activa, nunca llama al resolver de colisiones (cero '
        'queries de red adicionales)', () async {
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
      addTearDown(targetDb.close);
      final targetDatasource = buildDatasource(targetDb);

      final result =
          await targetDatasource.restore(path, mode: RestoreMode.merge);

      expect(result.isRight(), isTrue,
          reason: '${result.getLeft().toNullable()}');
      verifyNever(() => collisionResolver.findCollidingIds(
            userId: any(named: 'userId'),
            idsByTable: any(named: 'idsByTable'),
          ));
    });

    test(
        'con colisión, la fila se inserta localmente con un id UUID nuevo, '
        'nunca el id original', () async {
      const accountId = 'acc-1';
      await sourceDb.into(sourceDb.accounts).insert(
            AccountsCompanion.insert(
              id: const Value(accountId),
              name: 'Efectivo',
              type: AccountType.cash,
              currency: 'COP',
            ),
          );
      final path = p.join(tempDir.path, 'copia.billetudo.json');
      await sourceDatasource.createFullBackup(path);

      final resolver = MockBackupIdCollisionResolver();
      when(() => resolver.findCollidingIds(
            userId: 'user-1',
            idsByTable: any(named: 'idsByTable'),
          )).thenAnswer((_) async => const Right({
            'accounts': [accountId],
          }));
      final (targetDb, targetDatasource) = await buildSignedInTarget(resolver);

      final result =
          await targetDatasource.restore(path, mode: RestoreMode.merge);

      expect(result.isRight(), isTrue,
          reason: '${result.getLeft().toNullable()}');
      final accounts = await targetDb.select(targetDb.accounts).get();
      expect(accounts, hasLength(1));
      expect(
        accounts.single.id,
        isNot(accountId),
        reason: 'a colliding id must never be inserted with its original '
            'value — it belongs to another Supabase account',
      );
    });

    test(
        'con colisión, reescribe la FK que referencia el id remapeado antes '
        'de insertar (transactions.accountId)', () async {
      const accountId = 'acc-1';
      await sourceDb.into(sourceDb.accounts).insert(
            AccountsCompanion.insert(
              id: const Value(accountId),
              name: 'Efectivo',
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

      final resolver = MockBackupIdCollisionResolver();
      when(() => resolver.findCollidingIds(
            userId: 'user-1',
            idsByTable: any(named: 'idsByTable'),
          )).thenAnswer((_) async => const Right({
            'accounts': [accountId],
          }));
      final (targetDb, targetDatasource) = await buildSignedInTarget(resolver);

      final result =
          await targetDatasource.restore(path, mode: RestoreMode.merge);

      expect(result.isRight(), isTrue,
          reason: '${result.getLeft().toNullable()}');
      final accounts = await targetDb.select(targetDb.accounts).get();
      final transactions = await targetDb.select(targetDb.transactions).get();
      expect(accounts, hasLength(1));
      expect(transactions, hasLength(1));
      expect(
        transactions.single.accountId,
        accounts.single.id,
        reason: 'the FK must follow the remapped account id, never point at '
            'the original (colliding) one',
      );
    });

    test(
        'con colisión en categorías, el orden padre-antes-que-hijo sigue '
        'siendo correcto sobre los ids ya remapeados', () async {
      const parentId = 'parent-1';
      const childId = 'child-1';
      // Inserted child-first so the backup lists the child before the
      // parent, same setup as the non-collision topological order test.
      await sourceDb.into(sourceDb.categories).insert(
            CategoriesCompanion.insert(
              id: const Value(childId),
              name: 'Restaurantes',
              kind: CategoryKind.expense,
              parentId: const Value(parentId),
            ),
          );
      await sourceDb.into(sourceDb.categories).insert(
            CategoriesCompanion.insert(
              id: const Value(parentId),
              name: 'Comida y bebidas',
              kind: CategoryKind.expense,
            ),
          );
      final path = p.join(tempDir.path, 'copia.billetudo.json');
      await sourceDatasource.createFullBackup(path);

      final resolver = MockBackupIdCollisionResolver();
      when(() => resolver.findCollidingIds(
            userId: 'user-1',
            idsByTable: any(named: 'idsByTable'),
          )).thenAnswer((_) async => const Right({
            'categories': [parentId, childId],
          }));
      final (targetDb, targetDatasource) = await buildSignedInTarget(resolver);

      final result =
          await targetDatasource.restore(path, mode: RestoreMode.merge);

      expect(result.isRight(), isTrue,
          reason: '${result.getLeft().toNullable()}');
      final categories = await targetDb.select(targetDb.categories).get();
      expect(categories, hasLength(2));
      final newParent =
          categories.firstWhere((c) => c.parentId == null);
      final newChild = categories.firstWhere((c) => c.parentId != null);
      expect(newParent.id, isNot(parentId));
      expect(newChild.id, isNot(childId));
      expect(
        newChild.parentId,
        newParent.id,
        reason: '`parentId` must follow the remapped parent id',
      );
      final insertedOrder = await targetDb
          .customSelect('SELECT id FROM categories ORDER BY rowid')
          .get();
      final ids = insertedOrder.map((row) => row.read<String>('id')).toList();
      expect(
        ids,
        [newParent.id, newChild.id],
        reason: '_parentsBeforeChildren must operate on the remapped ids, '
            'not the backup\'s original ones — otherwise the parent-before-'
            'child guarantee silently breaks whenever categories collide',
      );
    });

    test(
        'si la detección de colisión falla por red, el restore aborta '
        'completo sin insertar ninguna fila (fail-closed)', () async {
      await sourceDb.into(sourceDb.accounts).insert(
            AccountsCompanion.insert(
              name: 'Efectivo',
              type: AccountType.cash,
              currency: 'COP',
            ),
          );
      final path = p.join(tempDir.path, 'copia.billetudo.json');
      await sourceDatasource.createFullBackup(path);

      final resolver = MockBackupIdCollisionResolver();
      when(() => resolver.findCollidingIds(
            userId: 'user-1',
            idsByTable: any(named: 'idsByTable'),
          )).thenAnswer(
        (_) async => const Left(NetworkFailure('sin red')),
      );
      final (targetDb, targetDatasource) = await buildSignedInTarget(resolver);

      final result =
          await targetDatasource.restore(path, mode: RestoreMode.merge);

      expect(result.getLeft().toNullable(), isA<NetworkFailure>());
      final accounts = await targetDb.select(targetDb.accounts).get();
      expect(accounts, isEmpty);
    });

    test(
        'restaurar la misma copia bajo dos cuentas distintas en el mismo '
        'dispositivo produce ids completamente disjuntos entre cuentas '
        '(regresión: ninguna operación de subida quedaría en cuarentena '
        'por un id duplicado tras ambas restauraciones)', () async {
      const accountId = 'acc-1';
      await sourceDb.into(sourceDb.accounts).insert(
            AccountsCompanion.insert(
              id: const Value(accountId),
              name: 'Efectivo',
              type: AccountType.cash,
              currency: 'COP',
            ),
          );
      final path = p.join(tempDir.path, 'copia.billetudo.json');
      await sourceDatasource.createFullBackup(path);

      // Account A restores first: Postgres has never seen this id under any
      // account yet, so nothing collides — same as today's zero-collision
      // path (AC1). `buildSignedInTarget` always signs in as `user-1` — a
      // second, distinct account is simulated by a *second* signed-in
      // target sharing that same `user-1` session id but a resolver that
      // now reports a collision, exactly the way two different real
      // Supabase accounts would produce two different collision outcomes
      // for the identical id.
      final resolverA = MockBackupIdCollisionResolver();
      when(() => resolverA.findCollidingIds(
            userId: 'user-1',
            idsByTable: any(named: 'idsByTable'),
          )).thenAnswer((_) async => const Right({}));
      final (dbA, datasourceA) = await buildSignedInTarget(resolverA);
      final resultA =
          await datasourceA.restore(path, mode: RestoreMode.merge);
      expect(resultA.isRight(), isTrue,
          reason: '${resultA.getLeft().toNullable()}');
      final idsA =
          (await dbA.select(dbA.accounts).get()).map((r) => r.id).toSet();
      expect(idsA, {accountId},
          reason: 'account A owns the id first, so no remap happens for it');

      // Account B, on the same device, restores the identical backup file
      // afterwards — by now Postgres has `acc-1` owned by A, so B's restore
      // must report (and remap) a collision, same as the single-account
      // collision tests above.
      final resolverB = MockBackupIdCollisionResolver();
      when(() => resolverB.findCollidingIds(
            userId: 'user-1',
            idsByTable: any(named: 'idsByTable'),
          )).thenAnswer((_) async => const Right({
            'accounts': [accountId],
          }));
      final (dbB, datasourceB) = await buildSignedInTarget(resolverB);
      final resultB =
          await datasourceB.restore(path, mode: RestoreMode.merge);
      expect(resultB.isRight(), isTrue,
          reason: '${resultB.getLeft().toNullable()}');
      final idsB =
          (await dbB.select(dbB.accounts).get()).map((r) => r.id).toSet();

      expect(
        idsB.intersection(idsA),
        isEmpty,
        reason: 'if both accounts ever upload their local rows, an id '
            'shared between them would collide as two competing `id` '
            'primary keys under different `user_id`s — a real Supabase '
            'restore under those conditions is precisely what would leave '
            'an operation quarantined (42501/23505). Disjoint id sets after '
            'the remap is the guarantee that never happens.',
      );
      expect(idsB, isNot(contains(accountId)));
    });
  });
}
