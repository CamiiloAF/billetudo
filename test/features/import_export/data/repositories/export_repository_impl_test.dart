import 'dart:io';

import 'package:billetudo/core/database/app_database.dart';
import 'package:billetudo/features/import_export/data/datasources/csv_writer_datasource.dart';
import 'package:billetudo/features/import_export/data/datasources/export_local_datasource.dart';
import 'package:billetudo/features/import_export/data/datasources/zip_packager_datasource.dart';
import 'package:billetudo/features/import_export/data/repositories/export_repository_impl.dart';
import 'package:billetudo/features/import_export/domain/entities/cancellation_token.dart';
import 'package:billetudo/features/import_export/domain/entities/csv_vocabulary.dart';
import 'package:billetudo/features/import_export/domain/entities/export_scope.dart';
import 'package:billetudo/features/import_export/domain/repositories/export_repository.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

/// Real Drift + real file IO (no mocks): this is exactly the case flagged as
/// a gap — `ExportRepository` must report real progress and honor
/// cancellation by deleting the partial file (HU-01/HU-09).
void main() {
  late Directory tempDir;
  late AppDatabase database;
  late ExportRepository repository;

  setUp(() async {
    tempDir = Directory.systemTemp.createTempSync('billetudo_export_test');
    database = AppDatabase(NativeDatabase.memory());
    repository = ExportRepositoryImpl(
      ExportLocalDatasource(database),
      const CsvWriterDatasource(),
      const ZipPackagerDatasource(),
    );
  });

  tearDown(() async {
    await database.close();
    if (tempDir.existsSync()) {
      tempDir.deleteSync(recursive: true);
    }
  });

  Future<String> insertAccount() async => (await database.into(database.accounts).insertReturning(
        AccountsCompanion.insert(name: 'Efectivo', type: AccountType.cash, currency: 'COP'),
      ))
          .id;

  group('exportTransactionsCsv', () {
    test('reporta progreso creciente hasta el total real de filas', () async {
      final accountId = await insertAccount();
      for (var i = 1; i <= 3; i++) {
        await database.into(database.transactions).insert(
              TransactionsCompanion.insert(
                accountId: accountId,
                amountMinor: i * 100,
                currency: 'COP',
                type: EntryType.expense,
                date: DateTime(2026, 1, i),
              ),
            );
      }
      final path = p.join(tempDir.path, 'export.csv');
      final calls = <(int, int?)>[];

      final result = await repository.exportTransactionsCsv(
        outputPath: path,
        scope: const ExportScope(includeTransactions: true, allHistory: true),
        language: CsvLanguage.es,
        onProgress: (processed, total) => calls.add((processed, total)),
      );

      expect(result.getRight().toNullable(), 3);
      expect(calls.first, (0, 3));
      expect(calls.last, (3, 3));
      for (var i = 1; i < calls.length; i++) {
        expect(calls[i].$1, greaterThanOrEqualTo(calls[i - 1].$1));
      }
      expect(File(path).existsSync(), isTrue);
    });

    test('cancelar a medio export borra el archivo parcial', () async {
      final accountId = await insertAccount();
      for (var i = 1; i <= 5; i++) {
        await database.into(database.transactions).insert(
              TransactionsCompanion.insert(
                accountId: accountId,
                amountMinor: i * 100,
                currency: 'COP',
                type: EntryType.expense,
                date: DateTime(2026, 1, i),
              ),
            );
      }
      final path = p.join(tempDir.path, 'export.csv');
      final token = CancellationToken();

      final result = await repository.exportTransactionsCsv(
        outputPath: path,
        scope: const ExportScope(includeTransactions: true, allHistory: true),
        language: CsvLanguage.es,
        onProgress: (processed, total) {
          if (processed == 2) {
            token.cancel();
          }
        },
        cancellationToken: token,
      );

      expect(result.isLeft(), isTrue);
      expect(File(path).existsSync(), isFalse);
    });
  });

  group('exportAccountsCsv', () {
    test('cancelar borra el archivo parcial y no escribe todas las cuentas',
        () async {
      for (var i = 1; i <= 4; i++) {
        await database.into(database.accounts).insert(
              AccountsCompanion.insert(
                name: 'Cuenta $i',
                type: AccountType.cash,
                currency: 'COP',
              ),
            );
      }
      final path = p.join(tempDir.path, 'cuentas.csv');
      final token = CancellationToken();

      final result = await repository.exportAccountsCsv(
        outputPath: path,
        language: CsvLanguage.es,
        onProgress: (processed, total) {
          if (processed == 1) {
            token.cancel();
          }
        },
        cancellationToken: token,
      );

      expect(result.isLeft(), isTrue);
      expect(File(path).existsSync(), isFalse);
    });
  });
}
