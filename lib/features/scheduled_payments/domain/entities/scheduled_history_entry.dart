import 'package:equatable/equatable.dart';

import '../../../transactions/domain/entities/transaction.dart' as tx;

/// One entry of a template's detail "Historial" (HU-05, page spec
/// "Histórico → Historial con omitidos"): a chronologically interleaved log of
/// what actually happened to the template's occurrences, most recent first.
///
/// Two kinds of event live in the same list:
///  - [ScheduledConfirmedHistoryEntry]: an occurrence that generated a real
///    transaction (`source: scheduled`) — it links back to that transaction.
///  - [ScheduledSkippedHistoryEntry]: an occurrence the user omitted, which
///    generated no transaction, so it only carries its own date and the
///    template's amount at the time.
///
/// Sealed so the presentation layer renders each kind exhaustively (confirmed
/// → `ScheduledPaymentHistoryRow`, skipped → `ScheduledSkippedHistoryRow`).
sealed class ScheduledHistoryEntry extends Equatable {
  const ScheduledHistoryEntry();

  /// The date the entry is sorted and displayed by: the transaction's date
  /// for a confirmed one, the occurrence's effective date
  /// (`snoozedToDate ?? occurrenceDate`) for a skipped one.
  DateTime get effectiveDate;
}

/// A confirmed occurrence: it produced [transaction] (`source: scheduled`).
class ScheduledConfirmedHistoryEntry extends ScheduledHistoryEntry {
  const ScheduledConfirmedHistoryEntry(this.transaction);

  final tx.Transaction transaction;

  @override
  DateTime get effectiveDate => transaction.date;

  @override
  List<Object?> get props => [transaction];
}

/// A skipped occurrence (HU-03): the user omitted it, so no transaction
/// exists. The amount shown (struck through in the UI) is the template's
/// amount at the time — the same value the hero renders, since a skipped
/// occurrence never captured one of its own.
class ScheduledSkippedHistoryEntry extends ScheduledHistoryEntry {
  const ScheduledSkippedHistoryEntry({
    required this.occurrenceId,
    required this.date,
    required this.amountMinor,
    required this.currency,
  });

  final String occurrenceId;

  /// The occurrence's effective date (`snoozedToDate ?? occurrenceDate`).
  final DateTime date;

  /// Always a positive integer of cents (the template's amount), never a
  /// `double` — same money rule as everywhere else.
  final int amountMinor;

  /// ISO-4217 code, e.g. 'COP'.
  final String currency;

  @override
  DateTime get effectiveDate => date;

  @override
  List<Object?> get props => [occurrenceId, date, amountMinor, currency];
}
