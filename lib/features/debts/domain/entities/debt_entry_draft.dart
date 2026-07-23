import 'package:equatable/equatable.dart';

import 'debt_entry.dart';

/// Input for persisting a solo-deuda [DebtEntry] (interest, adjustment, or a
/// cash-less payment/disbursement). [amountMinor] is already **signed** by the
/// use case that builds it (via `DebtEventRules`), so the repository writes it
/// verbatim. No `validated()`: the use cases own the rules and only reach the
/// repository with a well-formed, non-zero entry.
class DebtEntryDraft extends Equatable {
  const DebtEntryDraft({
    required this.debtId,
    required this.kind,
    required this.amountMinor,
    required this.entryDate,
    this.note,
    this.rateBpsSnapshot,
  });

  final String debtId;
  final DebtEntryKind kind;

  /// Signed: + increases the debt, − reduces it.
  final int amountMinor;

  final DateTime entryDate;
  final String? note;
  final int? rateBpsSnapshot;

  @override
  List<Object?> get props =>
      [debtId, kind, amountMinor, entryDate, note, rateBpsSnapshot];
}
