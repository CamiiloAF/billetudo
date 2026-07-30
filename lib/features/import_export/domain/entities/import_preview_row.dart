import 'package:equatable/equatable.dart';

import 'import_destination.dart';
import 'import_entry_type.dart';
import 'import_row_issue.dart';

/// HU-06/HU-07: what will happen to a CSV row if the import is confirmed as
/// currently configured.
enum ImportRowStatus {
  /// Will be imported (unless the user unchecks it).
  valid,

  /// Cannot be imported; not selectable (`zAusB` "Leading reemplazado").
  invalid,

  /// `id` matches an existing transaction — already imported. Omitted by
  /// default (HU-07).
  duplicateExact,

  /// Same account + amount + currency + type + date as an existing
  /// transaction, but no `id` match. A candidate, not a certainty — omitted
  /// by default, decided per-row by the user (HU-07).
  duplicateProbable,
}

/// A fully resolved preview row: `ParsedImportRow` plus where its account/
/// category/subcategory point to ([ImportDestination]) and its final
/// [status] (HU-06). This is what the preview screen renders and what
/// `ConfirmImport` writes from.
class ImportPreviewRow extends Equatable {
  const ImportPreviewRow({
    required this.rowNumber,
    required this.status,
    required this.includedByDefault,
    this.invalidIssue,
    this.sourceId,
    this.date,
    this.dateAmbiguous = false,
    this.amountMinor,
    this.amountRounded = false,
    this.type,
    this.currency,
    this.currencyMismatch = false,
    this.accountDestination,
    this.transferAccountDestination,
    this.categoryDestination,
    this.subcategoryDestination,
    this.note,
    this.tags = const <String>[],
    this.tagDestinations = const <ImportDestination>[],
  });

  final int rowNumber;
  final ImportRowStatus status;

  /// HU-07: `true` only for [ImportRowStatus.valid] — duplicates start
  /// unchecked, invalid rows are not selectable at all.
  final bool includedByDefault;

  /// Set only when [status] is [ImportRowStatus.invalid].
  final ImportRowIssue? invalidIssue;

  final String? sourceId;
  final DateTime? date;
  final bool dateAmbiguous;
  final int? amountMinor;
  final bool amountRounded;
  final ImportEntryType? type;
  final String? currency;

  /// True when [currency] differs from the destination account's currency
  /// and there is no cached exchange rate for the pair (`12-multi-moneda.md`
  /// HU-01): the row still imports with its own original amount/currency,
  /// this only flags it for the user, it never drops the row.
  final bool currencyMismatch;

  final ImportDestination? accountDestination;
  final ImportDestination? transferAccountDestination;
  final ImportDestination? categoryDestination;
  final ImportDestination? subcategoryDestination;
  final String? note;
  final List<String> tags;

  /// Resolved 1:1 with [tags], in the same order.
  final List<ImportDestination> tagDestinations;

  bool get isSelectable => status != ImportRowStatus.invalid;
  bool get isDuplicate =>
      status == ImportRowStatus.duplicateExact ||
      status == ImportRowStatus.duplicateProbable;

  @override
  List<Object?> get props => [
        rowNumber,
        status,
        includedByDefault,
        invalidIssue,
        sourceId,
        date,
        dateAmbiguous,
        amountMinor,
        amountRounded,
        type,
        currency,
        currencyMismatch,
        accountDestination,
        transferAccountDestination,
        categoryDestination,
        subcategoryDestination,
        note,
        tags,
        tagDestinations,
      ];
}
