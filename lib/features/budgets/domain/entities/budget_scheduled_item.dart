import 'package:equatable/equatable.dart';

/// One item behind a budget's "programado" figure (HU-12): an expense
/// scheduled-payment occurrence inside the period window that has not (yet)
/// materialized as a `Transaction`. Either a future date projected from a
/// template's cadence, or an occurrence already registered as `pending`
/// awaiting confirmation.
///
/// Enriched with everything the list/sheet row draws, mirror of
/// `BudgetActivityItem` but for what is not spent yet.
class BudgetScheduledItem extends Equatable {
  const BudgetScheduledItem({
    required this.id,
    required this.scheduledPaymentId,
    required this.note,
    required this.accountName,
    required this.amountMinor,
    required this.currency,
    required this.date,
    this.categoryIcon,
    this.categoryColor,
  });

  /// Unique within the period window: a `pending` occurrence's own id, or a
  /// synthetic `scheduledPaymentId@date` key for a still-projected date (one
  /// template can occur more than once in a window, e.g. weekly inside a
  /// monthly budget).
  final String id;

  /// The template this occurrence belongs to (for navigation to its detail).
  final String scheduledPaymentId;

  /// The template's raw note (its user-written name), or null when it has
  /// none. The row resolves the displayed title from it (note-first, generic
  /// fallback) via `ScheduledPaymentFormat.templateName` — never the category
  /// name (bugfix items 3/19).
  final String? note;

  /// Account the occurrence would be paid from; the row's subtitle leads with
  /// it, same convention as `BudgetActivityItem`.
  final String accountName;

  /// Category appearance tokens, null for an uncategorized occurrence.
  final String? categoryIcon;
  final String? categoryColor;

  final int amountMinor;
  final String currency;
  final DateTime date;

  @override
  List<Object?> get props => [
        id,
        scheduledPaymentId,
        note,
        accountName,
        categoryIcon,
        categoryColor,
        amountMinor,
        currency,
        date,
      ];
}
