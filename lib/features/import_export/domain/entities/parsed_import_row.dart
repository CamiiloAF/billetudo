import 'package:equatable/equatable.dart';

import 'import_entry_type.dart';
import 'import_row_issue.dart';

/// One CSV data row after applying a `ColumnMapping`/`CsvDialect`, before any
/// duplicate-detection or destination-resolution has run.
///
/// Pure domain shape: the *values* here (a `DateTime`, an `int` of cents) are
/// what crosses from `data/` into `domain` — the decimal/date string parsing
/// that produces them (exact integer arithmetic, half-up rounding; never
/// `double`) lives entirely in `data/`, per
/// `docs/requirements/fase-1/11-import-export.md` §Montos.
class ParsedImportRow extends Equatable {
  const ParsedImportRow({
    required this.rowNumber,
    this.sourceId,
    this.date,
    this.dateAmbiguous = false,
    this.amountMinor,
    this.amountRounded = false,
    this.type,
    this.currency,
    this.accountName,
    this.transferAccountName,
    this.categoryName,
    this.subcategoryName,
    this.note,
    this.tags = const <String>[],
    this.issue,
  });

  /// 1-based position among the file's *data* rows (excludes the header), so
  /// the UI can point the user back at the exact line to fix (HU-06).
  final int rowNumber;

  /// The `id` column's value, when mapped and present — the key for exact
  /// duplicate detection (HU-07).
  final String? sourceId;

  final DateTime? date;

  /// True when the source sample was ambiguous (every day <= 12) and the
  /// configured `DateComponentOrder` was only a guess (HU import §Fechas).
  final bool dateAmbiguous;

  /// Always positive; [type] (or the CSV's original sign, resolved by
  /// `data/`) carries the direction, same convention as `Transactions`.
  final int? amountMinor;

  /// True when the source had more decimals than the currency admits and the
  /// value was rounded half-up rather than discarded.
  final bool amountRounded;

  /// `null` only when the mapping has no `type` column — the row's amount
  /// sign already decided income vs. expense before this point, so `null`
  /// never reaches `ImportPreviewRow` as "unknown".
  final ImportEntryType? type;

  /// ISO-4217, uppercased. `null` = not mapped; the destination account's
  /// currency applies (HU-05).
  final String? currency;

  final String? accountName;
  final String? transferAccountName;
  final String? categoryName;
  final String? subcategoryName;
  final String? note;
  final List<String> tags;

  /// Non-null makes this row unimportable outright (missing/unparseable
  /// required field). `null` = the row parsed cleanly, though it may still
  /// turn out to be a duplicate.
  final ImportRowIssue? issue;

  bool get isParseValid => issue == null;

  @override
  List<Object?> get props => [
        rowNumber,
        sourceId,
        date,
        dateAmbiguous,
        amountMinor,
        amountRounded,
        type,
        currency,
        accountName,
        transferAccountName,
        categoryName,
        subcategoryName,
        note,
        tags,
        issue,
      ];
}
