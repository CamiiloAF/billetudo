import 'package:equatable/equatable.dart';

import 'scheduled_payment.dart';
import 'scheduled_payment_occurrence.dart';

/// A pending occurrence (HU-03) enriched with the template's current field
/// values and the display names the "por confirmar" list and the
/// confirmation sheet need.
///
/// The confirmation sheet (criterion 7) precargas `date`/`accountId`/
/// `amountMinor` as editable, and `categoryId`/`note`/`type`/`currency` as
/// read-only — all sourced from [scheduledPayment] as it stands *right now*,
/// never frozen at occurrence-creation time, so editing the template later
/// (before this occurrence is resolved) is reflected here.
///
/// Not listed verbatim in the original file plan, but indispensable for the
/// same reason as `ScheduledPaymentSummary`: the repository join that
/// resolves display names must land in `domain/`, not leak Drift types.
class PendingScheduledOccurrence extends Equatable {
  const PendingScheduledOccurrence({
    required this.occurrence,
    required this.scheduledPayment,
    required this.accountName,
    this.categoryName,
    this.categoryIcon,
    this.categoryColor,
    this.transferAccountName,
    this.tagIds = const <String>[],
  });

  final ScheduledPaymentOccurrence occurrence;
  final ScheduledPayment scheduledPayment;
  final String accountName;
  final String? categoryName;

  /// The category's `icon`/`color` tokens (see `CategoryAppearance`).
  final String? categoryIcon;
  final String? categoryColor;

  /// Only set when `scheduledPayment.type` is `transfer`.
  final String? transferAccountName;

  final List<String> tagIds;

  @override
  List<Object?> get props => [
        occurrence,
        scheduledPayment,
        accountName,
        categoryName,
        categoryIcon,
        categoryColor,
        transferAccountName,
        tagIds,
      ];
}
