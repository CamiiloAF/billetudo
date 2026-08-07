import '../../domain/entities/column_mapping.dart';
import '../../domain/entities/csv_dialect.dart';
import '../../domain/entities/mapping_template.dart';

/// JSON (de)serialization for [MappingTemplate], used by
/// `MappingTemplatesLocalDatasource` (local device storage — see that file's
/// doc for why it is not a Drift table).
abstract final class MappingTemplateJsonMapper {
  static Map<String, dynamic> toJson(MappingTemplate template) => {
        'name': template.name,
        'headerNames': template.headerNames,
        'dialect': {
          'fieldSeparator': template.dialect.fieldSeparator.name,
          'decimalConvention': template.dialect.decimalConvention.name,
          'dateOrder': template.dialect.dateOrder.name,
          'dateSeparator': template.dialect.dateSeparator.name,
        },
        'mapping': {
          'columns': {
            for (final entry in template.mapping.columns.entries)
              entry.key.name: entry.value,
          },
          if (template.mapping.typeValues case final values?)
            'typeValues': {
              'income': values.income,
              'expense': values.expense,
              'transfer': values.transfer,
            },
        },
        'savedAt': template.savedAt.toIso8601String(),
      };

  static MappingTemplate fromJson(Map<String, dynamic> json) {
    final dialectJson = json['dialect'] as Map<String, dynamic>;
    final mappingJson = json['mapping'] as Map<String, dynamic>;
    final columnsJson = mappingJson['columns'] as Map<String, dynamic>;
    final typeValuesJson = mappingJson['typeValues'] as Map<String, dynamic>?;

    return MappingTemplate(
      name: json['name'] as String,
      headerNames: (json['headerNames'] as List<dynamic>).cast<String>(),
      dialect: CsvDialect(
        fieldSeparator: CsvFieldSeparator.values.byName(
          dialectJson['fieldSeparator'] as String,
        ),
        decimalConvention: DecimalConvention.values.byName(
          dialectJson['decimalConvention'] as String,
        ),
        dateOrder: DateComponentOrder.values.byName(
          dialectJson['dateOrder'] as String,
        ),
        dateSeparator: DateSeparatorChar.values.byName(
          dialectJson['dateSeparator'] as String,
        ),
      ),
      mapping: ColumnMapping(
        columns: {
          for (final entry in columnsJson.entries)
            ImportField.values.byName(entry.key): entry.value as int,
        },
        typeValues: typeValuesJson == null
            ? null
            : TypeColumnValues(
                income: typeValuesJson['income'] as String,
                expense: typeValuesJson['expense'] as String,
                transfer: typeValuesJson['transfer'] as String,
              ),
      ),
      savedAt: DateTime.parse(json['savedAt'] as String),
    );
  }
}
