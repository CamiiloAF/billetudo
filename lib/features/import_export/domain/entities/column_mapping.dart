import 'package:equatable/equatable.dart';

/// The canonical fields a CSV column can be assigned to during import mapping
/// (HU-05). `id`, `type`, `currency`, `category`, `subcategory`,
/// `transferAccount`, `note` and `tags` are optional; `ColumnMapping.requiredFields`
/// lists the three that must be mapped for the file to be importable at all.
enum ImportField {
  id,
  date,
  amount,
  type,
  currency,
  account,
  transferAccount,
  category,
  subcategory,
  note,
  tags,
}

/// How a CSV row expresses income vs. expense when there is no `type` column
/// mapped: the sign of the amount itself (negative = gasto), per
/// `docs/requirements/11-import-export.md` §Montos.
class TypeColumnValues extends Equatable {
  const TypeColumnValues({
    required this.income,
    required this.expense,
    required this.transfer,
  });

  /// The literal value in the mapped `type` column that means income/expense/
  /// transfer (matched case-insensitively). E.g. `('ingreso', 'gasto',
  /// 'transferencia')` or `('income', 'expense', 'transfer')`.
  final String income;
  final String expense;
  final String transfer;

  @override
  List<Object?> get props => [income, expense, transfer];
}

/// User-confirmed (or autodetected) assignment of CSV columns to
/// [ImportField]s, plus how to read a `type` column when one is mapped
/// (HU-05/HU-06).
class ColumnMapping extends Equatable {
  const ColumnMapping({required this.columns, this.typeValues});

  /// Column index (0-based, matching the header row) for each mapped field.
  /// A field absent from this map is unmapped.
  final Map<ImportField, int> columns;

  /// Only meaningful when [ImportField.type] is mapped: the literal values
  /// that mean income/expense/transfer in that column. `null` when
  /// [ImportField.type] is unmapped — then the amount's sign carries the
  /// direction instead (income/expense only; a file with no type column
  /// cannot express transfers).
  final TypeColumnValues? typeValues;

  /// HU-05: fecha, monto y cuenta must always be mapped; everything else is
  /// optional.
  static const Set<ImportField> requiredFields = {
    ImportField.date,
    ImportField.amount,
    ImportField.account,
  };

  bool get isComplete => requiredFields.every(columns.containsKey);

  bool get hasTypeColumn => columns.containsKey(ImportField.type);

  int? columnFor(ImportField field) => columns[field];

  ColumnMapping copyWith({
    Map<ImportField, int>? columns,
    TypeColumnValues? typeValues,
  }) =>
      ColumnMapping(
        columns: columns ?? this.columns,
        typeValues: typeValues ?? this.typeValues,
      );

  @override
  List<Object?> get props => [columns, typeValues];
}
