import 'package:injectable/injectable.dart';

import '../entities/autodetected_mapping.dart';
import '../entities/column_mapping.dart';
import '../entities/csv_dialect.dart';
import '../entities/csv_vocabulary.dart';
import '../entities/mapping_template.dart';
import '../utils/text_normalizer.dart';

/// HU-05/06: prefills the mapping step from `headers` — a saved
/// [MappingTemplate] first (HU-06, "el usuario solo confirma"), then the
/// app's own export vocabulary in either language (HU-05, "autodetección del
/// formato propio"). Pure domain logic: no file I/O, `headers` already came
/// from `ParseCsvHeaders`.
@injectable
class AutodetectColumnMapping {
  const AutodetectColumnMapping();

  AutodetectedMapping call({
    required List<String> headers,
    required CsvDialect detectedDialect,
    List<MappingTemplate> savedTemplates = const [],
  }) {
    final normalizedHeaders = headers.map(normalizeForMatching).toList();

    for (final template in savedTemplates) {
      final normalizedTemplate =
          template.headerNames.map(normalizeForMatching).toList();
      if (_listsEqual(normalizedTemplate, normalizedHeaders)) {
        return AutodetectedMapping(
          mapping: template.mapping,
          dialect: template.dialect,
          matchedTemplateName: template.name,
        );
      }
    }

    final columns = <ImportField, int>{};
    TypeColumnValues? typeValues;
    for (final vocabulary in CsvVocabulary.all) {
      for (final column in TransactionCsvColumn.values) {
        final field = _fieldFor(column);
        if (field == null || columns.containsKey(field)) {
          continue;
        }
        final label = normalizeForMatching(vocabulary.transactionHeaders[column]!);
        final index = normalizedHeaders.indexOf(label);
        if (index != -1) {
          columns[field] = index;
          if (field == ImportField.type) {
            // Own-format autodetection (HU-05 "un toque"): the `tipo`/`type`
            // header matched this vocabulary, so its canonical
            // ingreso/gasto/transferencia (or income/expense/transfer)
            // literals are the values that column actually contains.
            typeValues = vocabulary.typeValues;
          }
        }
      }
    }

    return AutodetectedMapping(
      mapping: ColumnMapping(columns: columns, typeValues: typeValues),
      dialect: detectedDialect,
    );
  }

  /// `budgetable`/`source` (HU-01 export-only columns) have no [ImportField]
  /// counterpart — HU-05's mapping never accepts them as input.
  ImportField? _fieldFor(TransactionCsvColumn column) => switch (column) {
        TransactionCsvColumn.id => ImportField.id,
        TransactionCsvColumn.date => ImportField.date,
        TransactionCsvColumn.type => ImportField.type,
        TransactionCsvColumn.amount => ImportField.amount,
        TransactionCsvColumn.currency => ImportField.currency,
        TransactionCsvColumn.account => ImportField.account,
        TransactionCsvColumn.transferAccount => ImportField.transferAccount,
        TransactionCsvColumn.category => ImportField.category,
        TransactionCsvColumn.subcategory => ImportField.subcategory,
        TransactionCsvColumn.note => ImportField.note,
        TransactionCsvColumn.tags => ImportField.tags,
        TransactionCsvColumn.budgetable => null,
        TransactionCsvColumn.source => null,
      };

  bool _listsEqual(List<String> a, List<String> b) {
    if (a.length != b.length) {
      return false;
    }
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) {
        return false;
      }
    }
    return true;
  }
}
