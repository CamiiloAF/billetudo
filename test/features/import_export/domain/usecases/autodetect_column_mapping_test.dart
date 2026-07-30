import 'package:billetudo/features/import_export/domain/entities/column_mapping.dart';
import 'package:billetudo/features/import_export/domain/entities/csv_dialect.dart';
import 'package:billetudo/features/import_export/domain/entities/csv_vocabulary.dart';
import 'package:billetudo/features/import_export/domain/entities/mapping_template.dart';
import 'package:billetudo/features/import_export/domain/usecases/autodetect_column_mapping.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const usecase = AutodetectColumnMapping();
  const dialect = CsvDialect();

  group('formato propio de la app', () {
    test('encabezados en español se autodetectan completos', () {
      final result = usecase(
        headers: CsvVocabulary.es.transactionHeaderRow,
        detectedDialect: dialect,
      );

      expect(result.mapping.isComplete, isTrue);
      expect(result.mapping.columnFor(ImportField.date), 1);
      expect(result.mapping.columnFor(ImportField.amount), 3);
      expect(result.mapping.columnFor(ImportField.account), 5);
      expect(result.isOwnFormat, isTrue);
    });

    test('encabezados en inglés también se reconocen (round-trip cruzado)',
        () {
      final result = usecase(
        headers: CsvVocabulary.en.transactionHeaderRow,
        detectedDialect: dialect,
      );

      expect(result.mapping.isComplete, isTrue);
    });

    test('espacios/mayúsculas extra en los encabezados no rompen la detección',
        () {
      final headers = CsvVocabulary.es.transactionHeaderRow
          .map((h) => '  ${h.toUpperCase()}  ')
          .toList();

      final result = usecase(headers: headers, detectedDialect: dialect);

      expect(result.mapping.isComplete, isTrue);
    });

    test(
      'autodetectar mapea la columna "tipo" pero también debe poblar '
      'typeValues — sin esto, ImportRepositoryImpl marca TODA fila como '
      '"Tipo no reconocido" (invalidType) y la migración de un toque de '
      'HU-05 no importa ni una sola fila',
      () {
        final result = usecase(
          headers: CsvVocabulary.es.transactionHeaderRow,
          detectedDialect: dialect,
        );

        expect(result.mapping.hasTypeColumn, isTrue);
        expect(
          result.mapping.typeValues,
          isNotNull,
          reason: 'ImportRepositoryImpl.parseRow treats a mapped type '
              'column with null typeValues as ImportRowIssue.invalidType '
              'for every row (see its "values == null" branch) — '
              'AutodetectColumnMapping.call() builds `columns` but never '
              'sets `typeValues` on the returned mapping, so reimporting '
              "the app's own CSV export (the flagship \"un toque\" "
              'migration path) currently fails on every row.',
        );
        expect(result.mapping.typeValues, CsvVocabulary.es.typeValues);
      },
    );
  });

  group('archivo de otro origen', () {
    test('encabezados desconocidos no completan el mapeo (queda para el usuario)',
        () {
      final result = usecase(
        headers: const ['FECHA_MOV', 'MONTO_COP', 'DESCRIPCION'],
        detectedDialect: dialect,
      );

      expect(result.mapping.isComplete, isFalse);
      expect(result.mapping.columns, isEmpty);
    });

    test('un match parcial deja el resto para que el usuario lo complete',
        () {
      final result = usecase(
        headers: const ['fecha', 'monto', 'DESCRIPCION'],
        detectedDialect: dialect,
      );

      expect(result.mapping.columnFor(ImportField.date), 0);
      expect(result.mapping.columnFor(ImportField.amount), 1);
      expect(result.mapping.isComplete, isFalse); // falta "cuenta"
    });
  });

  group('plantillas guardadas (HU-06)', () {
    test('una plantilla cuyos encabezados coinciden se usa directamente', () {
      final template = MappingTemplate(
        name: 'Mi banco',
        headerNames: const ['FECHA_MOV', 'MONTO_COP', 'DESCRIPCION'],
        dialect: dialect,
        mapping: const ColumnMapping(
          columns: {
            ImportField.date: 0,
            ImportField.amount: 1,
            ImportField.account: 2,
          },
        ),
        savedAt: DateTime(2026, 1, 1),
      );

      final result = usecase(
        headers: const ['fecha_mov', 'monto_cop', 'descripcion'],
        detectedDialect: dialect,
        savedTemplates: [template],
      );

      expect(result.matchedTemplateName, 'Mi banco');
      expect(result.mapping.isComplete, isTrue);
    });
  });
}
