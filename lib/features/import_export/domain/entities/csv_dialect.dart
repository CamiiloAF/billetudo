import 'package:equatable/equatable.dart';

/// Field separator a CSV file uses (`docs/requirements/fase-1/11-import-export.md`
/// §Dialecto CSV). Export always writes [comma]; import detects one of the
/// three by reading the first lines, and the user can correct it.
enum CsvFieldSeparator { comma, semicolon, tab }

/// Which character acts as the decimal separator in a numeric column. Export
/// always writes [dot]; import lets the user choose (autodetected when
/// possible), because both conventions show up in real files.
enum DecimalConvention { dot, comma }

/// Order of date components in an import column. Export always writes
/// [isoYmd]; the other two only apply to import.
enum DateComponentOrder { isoYmd, dayMonthYear, monthDayYear }

/// Character separating date components in an import column (`03/04`,
/// `03-04`, `03.04`). Irrelevant for [DateComponentOrder.isoYmd], which is
/// always `-`.
enum DateSeparatorChar { dash, slash, dot }

/// The parsing rules for one CSV file: how fields are split and how its
/// amount/date columns read. Detected by `ParseCsvHeaders`/
/// `AutodetectColumnMapping` and refined by the user during the mapping step
/// (HU-05).
class CsvDialect extends Equatable {
  const CsvDialect({
    this.fieldSeparator = CsvFieldSeparator.comma,
    this.decimalConvention = DecimalConvention.dot,
    this.dateOrder = DateComponentOrder.isoYmd,
    this.dateSeparator = DateSeparatorChar.dash,
  });

  final CsvFieldSeparator fieldSeparator;
  final DecimalConvention decimalConvention;
  final DateComponentOrder dateOrder;
  final DateSeparatorChar dateSeparator;

  String get fieldSeparatorChar => switch (fieldSeparator) {
        CsvFieldSeparator.comma => ',',
        CsvFieldSeparator.semicolon => ';',
        CsvFieldSeparator.tab => '\t',
      };

  String get dateSeparatorChar => switch (dateSeparator) {
        DateSeparatorChar.dash => '-',
        DateSeparatorChar.slash => '/',
        DateSeparatorChar.dot => '.',
      };

  CsvDialect copyWith({
    CsvFieldSeparator? fieldSeparator,
    DecimalConvention? decimalConvention,
    DateComponentOrder? dateOrder,
    DateSeparatorChar? dateSeparator,
  }) =>
      CsvDialect(
        fieldSeparator: fieldSeparator ?? this.fieldSeparator,
        decimalConvention: decimalConvention ?? this.decimalConvention,
        dateOrder: dateOrder ?? this.dateOrder,
        dateSeparator: dateSeparator ?? this.dateSeparator,
      );

  @override
  List<Object?> get props => [
        fieldSeparator,
        decimalConvention,
        dateOrder,
        dateSeparator,
      ];
}
