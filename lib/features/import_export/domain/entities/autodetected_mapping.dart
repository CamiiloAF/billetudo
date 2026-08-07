import 'package:equatable/equatable.dart';

import 'column_mapping.dart';
import 'csv_dialect.dart';

/// What `AutodetectColumnMapping` could infer from a file's header row
/// (HU-05): either a saved template matched outright, or as many
/// [ImportField]s as the app's own export vocabulary (es/en) recognized.
/// [mapping] may still be incomplete — the mapping step just starts prefilled
/// instead of blank.
class AutodetectedMapping extends Equatable {
  const AutodetectedMapping({
    required this.mapping,
    required this.dialect,
    this.matchedTemplateName,
  });

  final ColumnMapping mapping;
  final CsvDialect dialect;

  /// Non-null when a saved `MappingTemplate` recognized this file's headers
  /// outright (HU-06) — "el usuario solo confirma".
  final String? matchedTemplateName;

  bool get isOwnFormat => mapping.isComplete && matchedTemplateName == null;

  @override
  List<Object?> get props => [mapping, dialect, matchedTemplateName];
}
