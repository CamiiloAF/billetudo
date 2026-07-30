import 'package:equatable/equatable.dart';

import 'column_mapping.dart';
import 'csv_dialect.dart';

/// A saved column mapping the user can reuse for the next file from the same
/// source (HU-06, "Mi banco", "Wallet"...).
class MappingTemplate extends Equatable {
  const MappingTemplate({
    required this.name,
    required this.headerNames,
    required this.dialect,
    required this.mapping,
    required this.savedAt,
  });

  /// User-chosen name (e.g. "Mi banco", "Wallet").
  final String name;

  /// The header row of the file this template was saved from, in file order.
  /// Used by `AutodetectColumnMapping` to recognize a later file from the
  /// same source even when headers are not byte-identical (case/space/accent
  /// insensitive match, same rule as destination resolution).
  final List<String> headerNames;

  final CsvDialect dialect;
  final ColumnMapping mapping;
  final DateTime savedAt;

  @override
  List<Object?> get props => [name, headerNames, dialect, mapping, savedAt];
}
