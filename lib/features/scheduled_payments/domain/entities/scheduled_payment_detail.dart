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

  /// First page (up to 3 rows, criterion 13) of transactions generated from
  /// this template, most recent first.
  final List<tx.Transaction> history;

  /// The total number of transactions ever generated from this template,
  /// regardless of how many are loaded in [history] — feeds "Ver historial
  /// completo (N)".
  final int historyTotalCount;

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
        history,
        historyTotalCount,
      ];
}
