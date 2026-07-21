import 'package:equatable/equatable.dart';

import '../../../transactions/domain/entities/transaction.dart' as tx;
import 'pending_scheduled_occurrence.dart';
import 'scheduled_payment.dart';
import 'tag.dart';

/// The hybrid "próximo pago + configuración" detail view of a template
/// (HU-05): its own fields, display names, tags, its pending occurrence when
/// one exists (HU-03), and the first page of its generation history
/// (criterion 13).
///
/// Reuses the Transactions feature's own `Transaction` entity for [history]
/// instead of duplicating a third mirror of it: those rows *are* real
/// transactions (`source: scheduled`), and every generated transaction's
/// detail page already renders a `Transaction` — same precedent as this
/// project reusing `CategoryKind` across features.
class ScheduledPaymentDetail extends Equatable {
  const ScheduledPaymentDetail({
    required this.scheduledPayment,
    required this.accountName,
    required this.historyTotalCount,
    this.categoryName,
    this.categoryIcon,
    this.categoryColor,
    this.transferAccountName,
    this.tags = const <Tag>[],
    this.pendingOccurrence,
    this.nextAwaitingDate,
    this.history = const <tx.Transaction>[],
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
  DateTime get nextPaymentDate =>
      nextAwaitingDate ?? scheduledPayment.nextDate;

  /// First page (up to 3 rows, criterion 13) of transactions generated from
  /// this template, most recent first.
  final List<tx.Transaction> history;

  /// The total number of transactions ever generated from this template,
  /// regardless of how many are loaded in [history] — feeds "Ver historial
  /// completo (N)".
  final int historyTotalCount;

  /// Whether this is a `once` template whose single transaction has already
  /// been generated — the fact `ScheduledPayment.isActive` asks the caller
  /// for, since the template itself has no column recording it fired. A
  /// generated transaction is exactly what [historyTotalCount] counts.
  bool get onceAlreadyGenerated =>
      scheduledPayment.frequency == ScheduledPaymentFrequency.once &&
      historyTotalCount > 0;

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
      ];
}
