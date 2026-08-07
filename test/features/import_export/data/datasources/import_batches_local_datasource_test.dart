import 'package:billetudo/core/database/app_database.dart' as db;
import 'package:billetudo/features/import_export/data/datasources/import_batches_local_datasource.dart';
import 'package:billetudo/features/import_export/domain/entities/cancellation_token.dart';
import 'package:billetudo/features/import_export/domain/entities/import_commit_plan.dart';
import 'package:billetudo/features/import_export/domain/entities/import_destination.dart';
import 'package:billetudo/features/import_export/domain/entities/import_entry_type.dart';
import 'package:billetudo/features/import_export/domain/entities/import_preview_row.dart';
import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late db.AppDatabase database;
  late ImportBatchesLocalDatasource datasource;

  setUp(() {
    database = db.AppDatabase(NativeDatabase.memory());
    datasource = ImportBatchesLocalDatasource(database);
  });

  tearDown(() => database.close());

  ImportPreviewRow expenseRow({
    required int rowNumber,
    required ImportDestination accountDestination,
    ImportDestination? categoryDestination,
    List<ImportDestination> tagDestinations = const [],
    List<String> tags = const [],
  }) =>
      ImportPreviewRow(
        rowNumber: rowNumber,
        status: ImportRowStatus.valid,
        includedByDefault: true,
        date: DateTime(2026, 1, rowNumber),
        amountMinor: 1000 * rowNumber,
        currency: 'COP',
        type: ImportEntryType.expense,
        accountDestination: accountDestination,
        categoryDestination: categoryDestination,
        tags: tags,
        tagDestinations: tagDestinations,
      );

  group('commitImport', () {
    test('crea una cuenta nueva una sola vez aunque varias filas la usen',
        () async {
      final plan = ImportCommitPlan(
        fileName: 'movimientos.csv',
        rows: [
          expenseRow(rowNumber: 1, accountDestination: const NewImportDestination('Efectivo')),
          expenseRow(rowNumber: 2, accountDestination: const NewImportDestination('Efectivo')),
        ],
        skippedDuplicateCount: 0,
        skippedErrorCount: 0,
      );

      await datasource.commitImport(plan);

      final accounts = await database.select(database.accounts).get();
      expect(accounts, hasLength(1));
      expect(accounts.single.name, 'Efectivo');
      expect(accounts.single.type, db.AccountType.other);
      expect(accounts.single.initialBalanceMinor, 0);

      final transactions = await database.select(database.transactions).get();
      expect(transactions, hasLength(2));
      expect(transactions.every((t) => t.accountId == accounts.single.id), isTrue);
      expect(transactions.every((t) => t.source == db.TxSource.imported), isTrue);
    });

    test('reporta progreso creciente, fila por fila', () async {
      final plan = ImportCommitPlan(
        fileName: 'movimientos.csv',
        rows: [
          expenseRow(rowNumber: 1, accountDestination: const NewImportDestination('Efectivo')),
          expenseRow(rowNumber: 2, accountDestination: const NewImportDestination('Efectivo')),
          expenseRow(rowNumber: 3, accountDestination: const NewImportDestination('Efectivo')),
        ],
        skippedDuplicateCount: 0,
        skippedErrorCount: 0,
      );
      final calls = <(int, int?)>[];

      await datasource.commitImport(
        plan,
        onProgress: (processed, total) => calls.add((processed, total)),
      );

      expect(calls.first, (0, 3));
      expect(calls.last, (3, 3));
      for (var i = 1; i < calls.length; i++) {
        expect(calls[i].$1, greaterThan(calls[i - 1].$1));
      }
    });

    test('cancelar a medio commit no deja ninguna fila escrita (rollback)',
        () async {
      final plan = ImportCommitPlan(
        fileName: 'movimientos.csv',
        rows: [
          expenseRow(rowNumber: 1, accountDestination: const NewImportDestination('Efectivo')),
          expenseRow(rowNumber: 2, accountDestination: const NewImportDestination('Efectivo')),
          expenseRow(rowNumber: 3, accountDestination: const NewImportDestination('Efectivo')),
        ],
        skippedDuplicateCount: 0,
        skippedErrorCount: 0,
      );
      final token = CancellationToken();

      await expectLater(
        datasource.commitImport(
          plan,
          onProgress: (processed, total) {
            if (processed == 2) {
              token.cancel();
            }
          },
          cancellationToken: token,
        ),
        throwsA(isA<Exception>()),
      );

      final transactions = await database.select(database.transactions).get();
      expect(transactions, isEmpty);
      final accounts = await database.select(database.accounts).get();
      expect(accounts, isEmpty);
      final batches = await database.select(database.importBatches).get();
      expect(batches, isEmpty);
    });

    test('cada transacción queda enlazada al lote por importBatchId',
        () async {
      final plan = ImportCommitPlan(
        fileName: 'movimientos.csv',
        rows: [
          expenseRow(rowNumber: 1, accountDestination: const NewImportDestination('Efectivo')),
        ],
        skippedDuplicateCount: 0,
        skippedErrorCount: 0,
      );

      final batch = await datasource.commitImport(plan);

      final transactions = await database.select(database.transactions).get();
      expect(transactions.single.importBatchId, batch.id);

      final accounts = await database.select(database.accounts).get();
      expect(accounts.single.importBatchId, batch.id);
    });

    test('una categoría existente se reutiliza por id, no se duplica',
        () async {
      final existing = await database.into(database.categories).insertReturning(
            db.CategoriesCompanion.insert(
              name: 'Comida',
              kind: db.CategoryKind.expense,
            ),
          );

      final plan = ImportCommitPlan(
        fileName: 'movimientos.csv',
        rows: [
          expenseRow(
            rowNumber: 1,
            accountDestination: const NewImportDestination('Efectivo'),
            categoryDestination: ExistingImportDestination(existing.id),
          ),
        ],
        skippedDuplicateCount: 0,
        skippedErrorCount: 0,
      );

      await datasource.commitImport(plan);

      final categories = await database.select(database.categories).get();
      expect(categories, hasLength(1));
      final transactions = await database.select(database.transactions).get();
      expect(transactions.single.categoryId, existing.id);
    });
  });

  group('undoBatch (HU-08)', () {
    test('deshacer trashea las transacciones del lote', () async {
      final plan = ImportCommitPlan(
        fileName: 'movimientos.csv',
        rows: [
          expenseRow(rowNumber: 1, accountDestination: const NewImportDestination('Efectivo')),
        ],
        skippedDuplicateCount: 0,
        skippedErrorCount: 0,
      );
      final batch = await datasource.commitImport(plan);

      final summary = await datasource.undoBatch(batch.id);

      expect(summary.transactionsTrashed, 1);
      final transactions = await database.select(database.transactions).get();
      expect(transactions.single.deletedAt, isNotNull);
    });

    test(
        'una cuenta creada por el lote y sin uso fuera de él se tombstona',
        () async {
      final plan = ImportCommitPlan(
        fileName: 'movimientos.csv',
        rows: [
          expenseRow(rowNumber: 1, accountDestination: const NewImportDestination('Efectivo')),
        ],
        skippedDuplicateCount: 0,
        skippedErrorCount: 0,
      );
      final batch = await datasource.commitImport(plan);

      final summary = await datasource.undoBatch(batch.id);

      expect(summary.accountsTrashed, 1);
      expect(summary.accountsKept, 0);
      final accounts = await database.select(database.accounts).get();
      expect(accounts.single.tombstonedAt, isNotNull);
    });

    test(
        'una cuenta creada por el lote pero usada luego a mano se conserva '
        '(HU-08: nunca se pierde uso fuera del lote)', () async {
      final plan = ImportCommitPlan(
        fileName: 'movimientos.csv',
        rows: [
          expenseRow(rowNumber: 1, accountDestination: const NewImportDestination('Efectivo')),
        ],
        skippedDuplicateCount: 0,
        skippedErrorCount: 0,
      );
      final batch = await datasource.commitImport(plan);
      final account = (await database.select(database.accounts).get()).single;

      // A manual transaction against the same account, created after the
      // import and outside the batch (`importBatchId` stays null).
      await database.into(database.transactions).insert(
            db.TransactionsCompanion.insert(
              accountId: account.id,
              amountMinor: 5000,
              currency: 'COP',
              type: db.EntryType.expense,
              date: DateTime(2026, 2, 1),
            ),
          );

      final summary = await datasource.undoBatch(batch.id);

      expect(summary.accountsKept, 1);
      expect(summary.accountsTrashed, 0);
      final accounts = await database.select(database.accounts).get();
      expect(accounts.single.tombstonedAt, isNull);
    });

    test('una categoría usada fuera del lote se conserva', () async {
      final plan = ImportCommitPlan(
        fileName: 'movimientos.csv',
        rows: [
          expenseRow(
            rowNumber: 1,
            accountDestination: const NewImportDestination('Efectivo'),
            categoryDestination: const NewImportDestination('Comida'),
          ),
        ],
        skippedDuplicateCount: 0,
        skippedErrorCount: 0,
      );
      final batch = await datasource.commitImport(plan);
      final category = (await database.select(database.categories).get()).single;
      final account = (await database.select(database.accounts).get()).single;

      await database.into(database.transactions).insert(
            db.TransactionsCompanion.insert(
              accountId: account.id,
              categoryId: Value(category.id),
              amountMinor: 5000,
              currency: 'COP',
              type: db.EntryType.expense,
              date: DateTime(2026, 2, 1),
            ),
          );

      final summary = await datasource.undoBatch(batch.id);

      expect(summary.categoriesKept, 1);
      expect(summary.categoriesTrashed, 0);
    });

    test(
        'una subcategoría del propio lote no hace que su raíz se vea '
        '"en uso" — ambas se destrashean si nada externo las usa', () async {
      final plan = ImportCommitPlan(
        fileName: 'movimientos.csv',
        rows: [
          ImportPreviewRow(
            rowNumber: 1,
            status: ImportRowStatus.valid,
            includedByDefault: true,
            date: DateTime(2026, 1, 1),
            amountMinor: 1000,
            currency: 'COP',
            type: ImportEntryType.expense,
            accountDestination: const NewImportDestination('Efectivo'),
            categoryDestination: const NewImportDestination('Comida'),
            subcategoryDestination:
                const NewImportDestination('Mercado', parentName: 'Comida'),
          ),
        ],
        skippedDuplicateCount: 0,
        skippedErrorCount: 0,
      );
      final batch = await datasource.commitImport(plan);

      final summary = await datasource.undoBatch(batch.id);

      expect(summary.categoriesTrashed, 2); // root + subcategory
      expect(summary.categoriesKept, 0);
    });

    test(
        'una subcategoría del lote usada fuera de él conserva también su '
        'raíz (para no dejar la subcategoría huérfana)', () async {
      final plan = ImportCommitPlan(
        fileName: 'movimientos.csv',
        rows: [
          ImportPreviewRow(
            rowNumber: 1,
            status: ImportRowStatus.valid,
            includedByDefault: true,
            date: DateTime(2026, 1, 1),
            amountMinor: 1000,
            currency: 'COP',
            type: ImportEntryType.expense,
            accountDestination: const NewImportDestination('Efectivo'),
            categoryDestination: const NewImportDestination('Comida'),
            subcategoryDestination:
                const NewImportDestination('Mercado', parentName: 'Comida'),
          ),
        ],
        skippedDuplicateCount: 0,
        skippedErrorCount: 0,
      );
      final batch = await datasource.commitImport(plan);
      final subcategory = (await database.select(database.categories).get())
          .firstWhere((c) => c.parentId != null);
      final account = (await database.select(database.accounts).get()).single;

      await database.into(database.transactions).insert(
            db.TransactionsCompanion.insert(
              accountId: account.id,
              categoryId: Value(subcategory.id),
              amountMinor: 5000,
              currency: 'COP',
              type: db.EntryType.expense,
              date: DateTime(2026, 2, 1),
            ),
          );

      final summary = await datasource.undoBatch(batch.id);

      expect(summary.categoriesKept, 2); // root + subcategory
      expect(summary.categoriesTrashed, 0);
    });

    test('el lote queda marcado revertido pero nunca se borra', () async {
      final plan = ImportCommitPlan(
        fileName: 'movimientos.csv',
        rows: [
          expenseRow(rowNumber: 1, accountDestination: const NewImportDestination('Efectivo')),
        ],
        skippedDuplicateCount: 0,
        skippedErrorCount: 0,
      );
      final batch = await datasource.commitImport(plan);

      await datasource.undoBatch(batch.id);

      final reverted = await datasource.getBatch(batch.id);
      expect(reverted, isNotNull);
      expect(reverted!.revertedAt, isNotNull);
    });
  });
}
