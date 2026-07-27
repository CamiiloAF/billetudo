import 'package:equatable/equatable.dart';

import 'scheduled_payment.dart';

/// A [ScheduledPayment] enriched with the display data the "próximos
/// vencimientos" list needs (HU-04): the name of its account and category.
///
/// Not listed verbatim in the original file plan, but indispensable: the list
/// shows "monto, cuenta y categoría" (criterion 11) and the repository join
/// that resolves those names must land somewhere outside `data/` — same
/// precedent as `transactions/domain/entities/transaction_with_details.dart`.
class ScheduledPaymentSummary extends Equatable {
  const ScheduledPaymentSummary({
    required this.scheduledPayment,
    required this.accountName,
    this.categoryName,
    this.categoryIcon,
    this.categoryColor,
    this.transferAccountName,
    this.pendingOccurrenceCount = 0,
    this.nextAwaitingDate,
    this.lastPaymentDate,
  });

  final ScheduledPayment scheduledPayment;
  final String accountName;
  final String? categoryName;

  /// The category's `icon`/`color` tokens (see `CategoryAppearance`), so the
  /// card's icon-wrap matches the same category coloring used across
  /// Transacciones/Home instead of a fixed brand tone.
  final String? categoryIcon;
  final String? categoryColor;

  /// Only set when `scheduledPayment.type` is `transfer`.
  final String? transferAccountName;

  /// >0 when this template currently has one or more pending occurrences
  /// (manual mode, HU-03) accumulated by the catch-up generator; the list
  /// shows it as a single row with a "×N" chip instead of repeating it
  /// (HU-04, criterion 11).
  final int pendingOccurrenceCount;

  /// Effective date of the nearest occurrence still awaiting resolution — a
  /// payment posponed ahead of its cadence. The card shows this instead of the
  /// template cursor so a snoozed payment reads its new date. Null when nothing
  /// is awaiting, in which case [nextPaymentDate] falls back to the cursor.
  final DateTime? nextAwaitingDate;

  /// The date the card shows as "próximo pago": the nearest awaiting
  /// occurrence's effective date when one exists, else the template cursor.
  DateTime get nextPaymentDate => nextAwaitingDate ?? scheduledPayment.nextDate;

  /// The effective date of the last occurrence this template actually
  /// generated (`confirmed` in the ledger), for the "Terminados" filter's
  /// "Último pago · 15 mar 2026" meta.
  ///
  /// Not the same as `endDate`: a repeating template stops at its `endDate`,
  /// but the last payment it really produced lands on the last cadence date
  /// before it — and a snoozed-then-confirmed occurrence lands on the date
  /// the user moved it to. Null when the template never fired (it reached
  /// `endDate` without generating anything).
  final DateTime? lastPaymentDate;

  bool get hasPendingOccurrence => pendingOccurrenceCount > 0;

  @override
  List<Object?> get props => [
        scheduledPayment,
        accountName,
        categoryName,
        categoryIcon,
        categoryColor,
        transferAccountName,
        pendingOccurrenceCount,
        nextAwaitingDate,
        lastPaymentDate,
      ];
}
