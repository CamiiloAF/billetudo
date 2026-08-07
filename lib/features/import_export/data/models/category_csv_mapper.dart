import '../../../../core/database/app_database.dart' as db;
import '../../domain/entities/csv_vocabulary.dart';

/// Builds one HU-02 CSV row from a `Categories` row. `parentName` is `''`
/// for a root category — the caller resolves it (a lookup by
/// `row.parentId`, not a query per row).
abstract final class CategoryCsvMapper {
  static List<String> toRow(
    db.Category row, {
    required String? parentName,
    required CsvVocabulary vocabulary,
  }) {
    final values = <CategoryCsvColumn, String>{
      CategoryCsvColumn.id: row.id,
      CategoryCsvColumn.name: row.name,
      CategoryCsvColumn.type: row.kind == db.CategoryKind.expense
          ? vocabulary.typeValues.expense
          : vocabulary.typeValues.income,
      CategoryCsvColumn.parentCategory: parentName ?? '',
      CategoryCsvColumn.parentId: row.parentId ?? '',
      CategoryCsvColumn.icon: row.icon ?? '',
      CategoryCsvColumn.color: row.color ?? '',
      CategoryCsvColumn.sortOrder: row.sortOrder.toString(),
    };
    return [for (final column in CategoryCsvColumn.values) values[column]!];
  }
}
