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
    List<List<String>> sampleRows = const [],
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
        if (index == -1) {
          continue;
        }
        if (field == ImportField.type) {
          // Own-format autodetection (HU-05 "un toque") is only valid if the
          // column's actual values look like this vocabulary's
          // ingreso/gasto/transferencia (or income/expense/transfer)
          // literals — a foreign export (e.g. Wallet/BudgetBakers) can reuse
          // the header text `tipo`/`type` for values ("Gastos"/"Ingresos")
          // that mean nothing to `ImportRepositoryImpl.parseRow`. Matching by
          // header alone there produced a false "complete" mapping that
          // failed every single row as `invalidType` instead of falling back
          // to the amount's sign. So leave the column unmapped (available for
          // manual mapping) unless at least one sampled value actually
          // matches.
          if (!_sampleValuesMatchVocabulary(sampleRows, index, vocabulary.typeValues)) {
            continue;
          }
          typeValues = vocabulary.typeValues;
        }
        columns[field] = index;
      }
    }

    return AutodetectedMapping(
      mapping: ColumnMapping(columns: columns, typeValues: typeValues),
      dialect: detectedDialect,
    );
  }

  /// True when at least one sample row has a non-empty value in [columnIndex]
  /// that matches (case-insensitively) one of [values]'s three literals.
  /// With no sample rows at all (e.g. an empty file) there is nothing to
  /// validate against, so the header match alone is trusted.
  bool _sampleValuesMatchVocabulary(
    List<List<String>> sampleRows,
    int columnIndex,
    TypeColumnValues values,
  ) {
    if (sampleRows.isEmpty) {
      return true;
    }
    final candidates = {
      values.income.toLowerCase(),
      values.expense.toLowerCase(),
      values.transfer.toLowerCase(),
    };
    for (final row in sampleRows) {
      if (columnIndex >= row.length) {
        continue;
      }
      final raw = row[columnIndex].trim().toLowerCase();
      if (raw.isNotEmpty && candidates.contains(raw)) {
        return true;
      }
    }
    return false;
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
