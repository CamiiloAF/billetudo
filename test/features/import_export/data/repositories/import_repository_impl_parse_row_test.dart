import 'package:billetudo/features/import_export/data/datasources/csv_parser_datasource.dart';
import 'package:billetudo/features/import_export/data/datasources/import_batches_local_datasource.dart';
import 'package:billetudo/features/import_export/data/datasources/import_destinations_local_datasource.dart';
import 'package:billetudo/features/import_export/data/repositories/import_repository_impl.dart';
import 'package:billetudo/features/import_export/domain/entities/column_mapping.dart';
import 'package:billetudo/features/import_export/domain/entities/csv_dialect.dart';
import 'package:billetudo/features/import_export/domain/entities/import_entry_type.dart';
import 'package:billetudo/features/import_export/domain/entities/import_row_issue.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockCsvParser extends Mock implements CsvParserDatasource {}

class _MockDestinations extends Mock implements ImportDestinationsLocalDatasource {}

class _MockBatches extends Mock implements ImportBatchesLocalDatasource {}

void main() {
  // `parseRow` is pure (no datasource calls), so the collaborators are never
  // exercised here — only present because the constructor requires them.
  final repository = ImportRepositoryImpl(
    _MockCsvParser(),
    _MockDestinations(),
    _MockBatches(),
  );

  const mapping = ColumnMapping(
    columns: {
      ImportField.date: 0,
      ImportField.amount: 1,
      ImportField.account: 2,
      ImportField.type: 3,
    },
    typeValues: TypeColumnValues(
      income: 'ingreso',
      expense: 'gasto',
      transfer: 'transferencia',
    ),
  );
  const dialect = CsvDialect();

  test('una fila completa se parsea con sus valores exactos', () {
    final row = repository.parseRow(
      ['2026-07-29', '19.99', 'Efectivo', 'gasto'],
      rowNumber: 1,
      mapping: mapping,
      dialect: dialect,
    );

    expect(row.issue, isNull);
    expect(row.date, DateTime(2026, 7, 29));
    expect(row.amountMinor, 1999);
    expect(row.accountName, 'Efectivo');
    expect(row.type, ImportEntryType.expense);
  });

  test('sin columna de tipo, el signo del monto decide la dirección', () {
    const mappingNoType = ColumnMapping(
      columns: {
        ImportField.date: 0,
        ImportField.amount: 1,
        ImportField.account: 2,
      },
    );

    final expenseRow = repository.parseRow(
      ['2026-07-29', '-19.99', 'Efectivo'],
      rowNumber: 1,
      mapping: mappingNoType,
      dialect: dialect,
    );
    expect(expenseRow.type, ImportEntryType.expense);
    expect(expenseRow.amountMinor, 1999); // siempre positivo

    final incomeRow = repository.parseRow(
      ['2026-07-29', '19.99', 'Efectivo'],
      rowNumber: 1,
      mapping: mappingNoType,
      dialect: dialect,
    );
    expect(incomeRow.type, ImportEntryType.income);
  });

  test('cuenta vacía es fila inválida por campo obligatorio faltante', () {
    final row = repository.parseRow(
      ['2026-07-29', '19.99', '', 'gasto'],
      rowNumber: 1,
      mapping: mapping,
      dialect: dialect,
    );

    expect(row.issue, ImportRowIssue.missingAccount);
  });

  test('fecha inválida se reporta sin bloquear el resto del archivo', () {
    final row = repository.parseRow(
      ['31/31/2026', '19.99', 'Efectivo', 'gasto'],
      rowNumber: 1,
      mapping: mapping,
      dialect: dialect,
    );

    expect(row.issue, ImportRowIssue.invalidDate);
  });

  test('monto no numérico es inválido', () {
    final row = repository.parseRow(
      ['2026-07-29', 'no-es-un-monto', 'Efectivo', 'gasto'],
      rowNumber: 1,
      mapping: mapping,
      dialect: dialect,
    );

    expect(row.issue, ImportRowIssue.invalidAmount);
  });

  test('un valor de tipo que no coincide con ninguno configurado es inválido',
      () {
    final row = repository.parseRow(
      ['2026-07-29', '19.99', 'Efectivo', 'no-es-un-tipo'],
      rowNumber: 1,
      mapping: mapping,
      dialect: dialect,
    );

    expect(row.issue, ImportRowIssue.invalidType);
  });

  test('etiquetas separadas por ; se dividen y recortan', () {
    const mappingWithTags = ColumnMapping(
      columns: {
        ImportField.date: 0,
        ImportField.amount: 1,
        ImportField.account: 2,
        ImportField.tags: 3,
      },
    );

    final row = repository.parseRow(
      ['2026-07-29', '19.99', 'Efectivo', ' viaje ; comida;trabajo '],
      rowNumber: 1,
      mapping: mappingWithTags,
      dialect: dialect,
    );

    expect(row.tags, ['viaje', 'comida', 'trabajo']);
  });
}
