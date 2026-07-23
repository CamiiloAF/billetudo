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
    this.debtStartDate,
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

  /// The owning debt's `startDate`, resolved only when this occurrence belongs
  /// to a cuota (`scheduledPayment.debtId != null`) and the debt still records
  /// one — null for an ordinary scheduled payment. It is the floor the
  /// confirmation sheet's date picker enforces: a cuota can never record a
  /// movement dated before the debt began.
  final DateTime? debtStartDate;

  /// The earliest date this occurrence may be confirmed on: the owning debt's
  /// `startDate` for a cuota, `null` (no floor) for an ordinary scheduled
  /// payment. Gated on `debtId` so a stray `debtStartDate` on a non-cuota can
  /// never impose a floor.
  DateTime? get confirmationMinDate =>
      scheduledPayment.debtId != null ? debtStartDate : null;

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
        debtStartDate,
      ];
}
