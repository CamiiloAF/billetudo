import 'package:billetudo/features/import_export/data/models/mapping_template_json_mapper.dart';
import 'package:billetudo/features/import_export/domain/entities/column_mapping.dart';
import 'package:billetudo/features/import_export/domain/entities/csv_dialect.dart';
import 'package:billetudo/features/import_export/domain/entities/mapping_template.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('toJson/fromJson hacen un round-trip exacto (HU-06)', () {
    final template = MappingTemplate(
      name: 'Mi banco',
      headerNames: const ['FECHA_MOV', 'MONTO_COP', 'DESCRIPCION'],
      dialect: const CsvDialect(
        fieldSeparator: CsvFieldSeparator.semicolon,
        decimalConvention: DecimalConvention.comma,
        dateOrder: DateComponentOrder.dayMonthYear,
        dateSeparator: DateSeparatorChar.slash,
      ),
      mapping: const ColumnMapping(
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
      ),
      savedAt: DateTime(2026, 7, 29, 10, 30),
    );

    final json = MappingTemplateJsonMapper.toJson(template);
    final restored = MappingTemplateJsonMapper.fromJson(json);

    expect(restored, template);
  });

  test('un mapeo sin columna de tipo no serializa typeValues', () {
    final template = MappingTemplate(
      name: 'Sin tipo',
      headerNames: const ['fecha', 'monto', 'cuenta'],
      dialect: const CsvDialect(),
      mapping: const ColumnMapping(
        columns: {
          ImportField.date: 0,
          ImportField.amount: 1,
          ImportField.account: 2,
        },
      ),
      savedAt: DateTime(2026, 1, 1),
    );

    final json = MappingTemplateJsonMapper.toJson(template);

    expect((json['mapping'] as Map).containsKey('typeValues'), isFalse);
    expect(MappingTemplateJsonMapper.fromJson(json).mapping.typeValues, isNull);
  });
}
