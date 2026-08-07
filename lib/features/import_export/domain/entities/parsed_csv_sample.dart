import 'package:equatable/equatable.dart';

import 'csv_dialect.dart';

/// What `ParseCsvHeaders` reads from a candidate import file before any
/// mapping decision (HU-05): its header row, a handful of data rows to show
/// live in the mapping step, and the dialect autodetected from them.
class ParsedCsvSample extends Equatable {
  const ParsedCsvSample({
    required this.headers,
    required this.sampleRows,
    required this.dialect,
    required this.totalDataRowCount,
  });

  final List<String> headers;

  /// First few data rows (excludes the header), for the mapping step's live
  /// preview.
  final List<List<String>> sampleRows;

  final CsvDialect dialect;

  /// Total data rows in the file (excludes the header) — read once here so
  /// the mapping/preview steps do not need to re-scan the file just to know
  /// the count.
  final int totalDataRowCount;

  @override
  List<Object?> get props => [headers, sampleRows, dialect, totalDataRowCount];
}
