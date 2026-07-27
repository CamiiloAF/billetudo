import 'package:equatable/equatable.dart';

import 'pending_scheduled_occurrence.dart';
import 'scheduled_history_entry.dart';
import 'scheduled_payment.dart';
import 'scheduled_payment_linked_debt.dart';
import 'tag.dart';

/// The hybrid "próximo pago + configuración" detail view of a template
/// (HU-05): its own fields, display names, tags, its pending occurrence when
/// one exists (HU-03), and the first page of its history (criterion 13).
///
/// The [history] is a chronologically interleaved log of confirmed *and*
/// skipped occurrences (page spec "Histórico → Historial con omitidos"), not
/// just generated transactions — see [ScheduledHistoryEntry].
class ScheduledPaymentDetail extends Equatable {
  const ScheduledPaymentDetail({
    required this.scheduledPayment,
    required this.accountName,
    required this.historyTotalCount,
    this.generatedTransactionCount = 0,
    this.categoryName,
    this.categoryIcon,
    this.categoryColor,
    this.transferAccountName,
    this.tags = const <Tag>[],
    this.pendingOccurrence,
    this.nextAwaitingDate,
    this.history = const <ScheduledHistoryEntry>[],
    this.linkedDebt,
  });

  final ScheduledPayment scheduledPayment;
  final String accountName;
  final String? categoryName;
  final String? categoryIcon;
  final String? categoryColor;

  /// Only set when `scheduledPayment.type` is `transfer`.
  final String? transferAccountName;

  final List<Tag> tags;

  /// Non-null when the template is in manual mode and its next due date is
  /// currently sitting as an unresolved occurrence (HU-03). Null means the
  /// next occurrence has not become due yet (still just
  /// `scheduledPayment.nextDate`) or the template is in automatic mode.
  final PendingScheduledOccurrence? pendingOccurrence;

  /// Effective date (`snoozedToDate ?? occurrenceDate`) of the nearest
  /// occurrence still awaiting resolution — including a snoozed one moved into
  /// the future. It is the actual "próximo pago" the hero shows: a snoozed
  /// payment must display its postponed date, not the template's cursor.
  /// `null` when no occurrence is awaiting, in which case the cursor
  /// (`scheduledPayment.nextDate`) is the next date.
  final DateTime? nextAwaitingDate;

  /// The date the hero shows as "próximo pago": the awaiting occurrence's
  /// effective date when one exists, else the template's cursor.
  DateTime get nextPaymentDate => nextAwaitingDate ?? scheduledPayment.nextDate;

  /// First page (up to 3 rows, criterion 13) of the template's history —
  /// confirmed and skipped occurrences interleaved, most recent first.
  final List<ScheduledHistoryEntry> history;

  /// The total number of history events (confirmed transactions + skipped
  /// occurrences) of this template, regardless of how many are loaded in
  /// [history] — feeds "Ver historial completo (N)".
  final int historyTotalCount;

  /// Non-null when this template is a debt's cuota
  /// (`scheduledPayment.debtId != null`): the debt it belongs to, for the
  /// "Cuota de …" cross-link card and the edit deep-link back to the debt's
  /// Configurar-cuota screen (HU-03).
  final ScheduledPaymentLinkedDebt? linkedDebt;

  /// How many transactions this template has actually generated (`confirmed`
  /// occurrences). A subset of [historyTotalCount], which also counts skipped
  /// occurrences: [onceAlreadyGenerated] keys off this, not the combined
  /// total, so a `once` template that was *skipped* (no transaction ever
  /// generated) does not read as already fired.
  final int generatedTransactionCount;

  /// Whether this is a `once` template whose single transaction has already
  /// been generated — the fact `ScheduledPayment.isActive` asks the caller
  /// for, since the template itself has no column recording it fired. Keyed
  /// on [generatedTransactionCount], never the combined history total.
  bool get onceAlreadyGenerated =>
      scheduledPayment.frequency == ScheduledPaymentFrequency.once &&
      generatedTransactionCount > 0;

  /// Whether the template still produces future occurrences: drives the
  /// hero's "PRÓXIMO PAGO" vs. "PAGO EJECUTADO" and the ficha's
  /// "Activa"/"Terminada" (Pencil `OY2Kj` vs. `Eyold`).
  bool get isActive =>
      scheduledPayment.isActive(onceAlreadyGenerated: onceAlreadyGenerated);

  @override
  List<Object?> get props => [
        scheduledPayment,
        accountName,
        categoryName,
        categoryIcon,
        categoryColor,
        transferAccountName,
        tags,
        pendingOccurrence,
        nextAwaitingDate,
        history,
        historyTotalCount,
        generatedTransactionCount,
        linkedDebt,
      ];
}
