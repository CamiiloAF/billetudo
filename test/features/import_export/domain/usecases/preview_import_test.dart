import 'package:billetudo/core/error/result.dart';
import 'package:billetudo/features/import_export/domain/entities/column_mapping.dart';
import 'package:billetudo/features/import_export/domain/entities/csv_dialect.dart';
import 'package:billetudo/features/import_export/domain/entities/import_destination.dart';
import 'package:billetudo/features/import_export/domain/entities/import_entry_type.dart';
import 'package:billetudo/features/import_export/domain/entities/import_preview_row.dart';
import 'package:billetudo/features/import_export/domain/entities/import_row_issue.dart';
import 'package:billetudo/features/import_export/domain/entities/named_entity.dart';
import 'package:billetudo/features/import_export/domain/entities/parsed_import_row.dart';
import 'package:billetudo/features/import_export/domain/repositories/import_repository.dart';
import 'package:billetudo/features/import_export/domain/usecases/preview_import.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'import_repository_mock.dart';

void main() {
  late MockImportRepository repository;
  late PreviewImport previewImport;

  const mapping = ColumnMapping(
    columns: {
      ImportField.date: 0,
      ImportField.amount: 1,
      ImportField.account: 2,
    },
  );
  const dialect = CsvDialect();

  setUpAll(registerImportRepositoryFallbacks);

  setUp(() {
    repository = MockImportRepository();
    previewImport = PreviewImport(repository);

    when(() => repository.getExistingAccounts())
        .thenAnswer((_) async => const Right([]));
    when(() => repository.getExistingRootCategories(isExpense: any(named: 'isExpense')))
        .thenAnswer((_) async => const Right([]));
    when(() => repository.getExistingSubcategories(any()))
        .thenAnswer((_) async => const Right([]));
    when(() => repository.getExistingTags())
        .thenAnswer((_) async => const Right([]));
    when(() => repository.findExistingTransactionIds(any()))
        .thenAnswer((_) async => const Right(<String>{}));
    when(() => repository.findProbableDuplicates(any()))
        .thenAnswer((_) async => const Right(<ProbableDuplicateSignature>{}));
  });

  void stubRows(Map<int, ParsedImportRow> rowsByNumber) {
    when(() => repository.readAllRows(any(), dialect: any(named: 'dialect')))
        .thenAnswer(
      (_) async => Right([
        for (var i = 0; i < rowsByNumber.length; i++) ['raw'],
      ]),
    );
    when(
      () => repository.parseRow(
        any(),
        rowNumber: any(named: 'rowNumber'),
        mapping: any(named: 'mapping'),
        dialect: any(named: 'dialect'),
      ),
    ).thenAnswer((invocation) {
      final rowNumber = invocation.namedArguments[#rowNumber] as int;
      return rowsByNumber[rowNumber]!;
    });
  }

  test('un mapeo incompleto se rechaza sin leer el archivo', () async {
    final result = await previewImport(
      filePath: 'x.csv',
      mapping: const ColumnMapping(columns: {ImportField.date: 0}),
      dialect: dialect,
    );

    expect(result.isLeft(), isTrue);
    verifyNever(() => repository.readAllRows(any(), dialect: any(named: 'dialect')));
  });

  group('HU-06 — resolución de destinos', () {
    test(
        'un nombre existente se resuelve ignorando mayúsculas/tildes/espacios',
        () async {
      when(() => repository.getExistingAccounts()).thenAnswer(
        (_) async => const Right([NamedEntity(id: 'acc-1', name: 'Comida y Bebida')]),
      );
      stubRows({
        1: ParsedImportRow(
          rowNumber: 1,
          date: DateTime(2026, 1, 1),
          amountMinor: 1000,
          type: ImportEntryType.expense,
          accountName: '  comida   y  bebida  ',
        ),
      });

      final result = await previewImport(filePath: 'x.csv', mapping: mapping, dialect: dialect);

      final row = result.getRight().toNullable()!.rows.single;
      expect(row.accountDestination, const ExistingImportDestination('acc-1'));
    });

    test('un nombre sin match se marca para crear, nunca se pierde la fila',
        () async {
      stubRows({
        1: ParsedImportRow(
          rowNumber: 1,
          date: DateTime(2026, 1, 1),
          amountMinor: 1000,
          type: ImportEntryType.expense,
          accountName: 'Cuenta Nueva',
        ),
      });

      final result = await previewImport(filePath: 'x.csv', mapping: mapping, dialect: dialect);

      final row = result.getRight().toNullable()!.rows.single;
      expect(row.accountDestination, const NewImportDestination('Cuenta Nueva'));
      expect(row.status, ImportRowStatus.valid);
    });

    test('un override del usuario prevalece sobre el match automático',
        () async {
      when(() => repository.getExistingAccounts()).thenAnswer(
        (_) async => const Right([NamedEntity(id: 'acc-1', name: 'Efectivo')]),
      );
      stubRows({
        1: ParsedImportRow(
          rowNumber: 1,
          date: DateTime(2026, 1, 1),
          amountMinor: 1000,
          type: ImportEntryType.expense,
          accountName: 'Efectivo',
        ),
      });

      final result = await previewImport(
        filePath: 'x.csv',
        mapping: mapping,
        dialect: dialect,
        accountOverrides: const {'efectivo': NewImportDestination('Efectivo')},
      );

      final row = result.getRight().toNullable()!.rows.single;
      expect(row.accountDestination, const NewImportDestination('Efectivo'));
    });
  });

  group('HU-07 — detección de duplicados', () {
    test('id existente se marca como duplicado exacto y omitido por defecto',
        () async {
      when(() => repository.findExistingTransactionIds(any()))
          .thenAnswer((_) async => const Right({'tx-1'}));
      stubRows({
        1: ParsedImportRow(
          rowNumber: 1,
          sourceId: 'tx-1',
          date: DateTime(2026, 1, 1),
          amountMinor: 1000,
          type: ImportEntryType.expense,
          accountName: 'Efectivo',
        ),
      });

      final result = await previewImport(filePath: 'x.csv', mapping: mapping, dialect: dialect);

      final row = result.getRight().toNullable()!.rows.single;
      expect(row.status, ImportRowStatus.duplicateExact);
      expect(row.includedByDefault, isFalse);
    });

    test(
        'misma cuenta+monto+moneda+tipo+fecha sin id es duplicado probable',
        () async {
      when(() => repository.getExistingAccounts()).thenAnswer(
        (_) async => const Right([NamedEntity(id: 'acc-1', name: 'Efectivo')]),
      );
      final signature = ProbableDuplicateSignature(
        accountId: 'acc-1',
        amountMinor: 1000,
        currency: 'COP',
        type: ImportEntryType.expense.name,
        date: DateTime(2026, 1, 1),
      );
      when(() => repository.findProbableDuplicates(any()))
          .thenAnswer((_) async => Right({signature}));
      stubRows({
        1: ParsedImportRow(
          rowNumber: 1,
          date: DateTime(2026, 1, 1),
          amountMinor: 1000,
          currency: 'COP',
          type: ImportEntryType.expense,
          accountName: 'Efectivo',
        ),
      });

      final result = await previewImport(filePath: 'x.csv', mapping: mapping, dialect: dialect);

      final row = result.getRight().toNullable()!.rows.single;
      expect(row.status, ImportRowStatus.duplicateProbable);
      expect(row.includedByDefault, isFalse);
    });

    test('dos gastos iguales el mismo día en una cuenta nueva no son duplicado',
        () async {
      // A brand new account cannot already have a colliding transaction —
      // PreviewImport must not even query for it.
      stubRows({
        1: ParsedImportRow(
          rowNumber: 1,
          date: DateTime(2026, 1, 1),
          amountMinor: 1000,
          currency: 'COP',
          type: ImportEntryType.expense,
          accountName: 'Cuenta Nueva',
        ),
      });

      final result = await previewImport(filePath: 'x.csv', mapping: mapping, dialect: dialect);

      final row = result.getRight().toNullable()!.rows.single;
      expect(row.status, ImportRowStatus.valid);
    });
  });

  group('HU-06 — validación de filas', () {
    test('una fila inválida no bloquea el resto y no es seleccionable',
        () async {
      when(() => repository.getExistingAccounts()).thenAnswer(
        (_) async => const Right([]),
      );
      stubRows({
        1: const ParsedImportRow(
          rowNumber: 1,
          issue: ImportRowIssue.missingAmount,
        ),
        2: ParsedImportRow(
          rowNumber: 2,
          date: DateTime(2026, 1, 1),
          amountMinor: 1000,
          type: ImportEntryType.expense,
          accountName: 'Efectivo',
        ),
      });

      final result = await previewImport(filePath: 'x.csv', mapping: mapping, dialect: dialect);

      final rows = result.getRight().toNullable()!.rows;
      expect(rows[0].status, ImportRowStatus.invalid);
      expect(rows[0].isSelectable, isFalse);
      expect(rows[1].status, ImportRowStatus.valid);
    });
  });
}
