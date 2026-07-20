import 'package:equatable/equatable.dart';

/// The nature of a scheduled payment. Mirrors `EntryType`, but is declared in
/// this feature's own domain (not imported from Transactions) because a
/// template is a standalone concept: it exists, can be edited and shows up
/// in "próximos vencimientos" even if it has never generated a transaction.
enum ScheduledPaymentType { income, expense, transfer }

/// How often a scheduled payment repeats. Mirrors `ScheduleFrequency`. `once`
/// generates a single transaction on [ScheduledPayment.nextDate] and then
/// never fires again (HU-01).
enum ScheduledPaymentFrequency { once, daily, weekly, monthly, yearly }

/// A template for a scheduled payment: a planned future transaction, one-time
/// or repeating (rent, subscriptions, a one-off future payment moved from
/// Transacciones via HU-06).
///
/// Pure domain entity: no Drift types, no `double`. `amountMinor` is always a
/// positive integer of minor units (cents); the sign/effect on the balance is
/// determined by [type], same rule as `Transaction`.
class ScheduledPayment extends Equatable {
  const ScheduledPayment({
    required this.id,
    required this.accountId,
    required this.amountMinor,
    required this.currency,
    required this.type,
    required this.frequency,
    required this.interval,
    required this.firstPaymentDate,
    required this.nextDate,
    required this.requiresConfirmation,
    required this.createdAt,
    required this.updatedAt,
    this.categoryId,
    this.note,
    this.transferAccountId,
    this.endDate,
    this.tombstonedAt,
  });

  /// UUID as text.
  final String id;

  final String accountId;

  /// Optional, restricted to a category whose `kind` matches [type]. Never
  /// set for a `transfer`.
  final String? categoryId;

  /// Always a positive integer of cents. The sign is determined by [type].
  final int amountMinor;

  /// ISO-4217 code, e.g. 'COP', 'USD'.
  final String currency;

  final ScheduledPaymentType type;
  final String? note;

  /// Only set when [type] is `transfer`: the destination account, same rule
  /// as a normal transfer transaction.
  final String? transferAccountId;

  final ScheduledPaymentFrequency frequency;

  /// How many [frequency] units between repeats. Ignored (normalized to 1)
  /// when [frequency] is `once`.
  final int interval;

  /// The date the user originally picked as the first payment when the
  /// template was created. IMMUTABLE: unlike [nextDate], it is set once at
  /// creation and never rewritten afterwards — it is not a cursor, it is a
  /// historical fact. This is what the UI must show for "Primer pago" so it
  /// never appears to change on its own as the catch-up generator advances
  /// [nextDate].
  final DateTime firstPaymentDate;

  /// The next due date the catch-up generator (HU-02) has not yet processed.
  /// Advances by [frequency]/[interval] only when the generator processes it;
  /// never mutated by confirming, skipping or snoozing an individual
  /// occurrence (HU-03/HU-07 — those act on `ScheduledPaymentOccurrence`
  /// rows, not on this field).
  final DateTime nextDate;

  /// Optional stop-generating date. Once [nextDate] passes it, the template
  /// stops producing new occurrences but is not deleted (HU-01).
  final DateTime? endDate;

  /// When true, reaching a due date creates a pending occurrence the user
  /// must confirm before it affects the balance (HU-03), instead of applying
  /// it automatically.
  final bool requiresConfirmation;

  final DateTime createdAt;

  /// Epoch millis, not a `DateTime` — see `_SyncColumns.updatedAt`.
  final int updatedAt;

  /// Non-null once the template has been deleted (HU-05): the row survives
  /// as a historical reference for transactions already generated from it,
  /// per the `tombstonedAt` convention (irreversible, referential-integrity
  /// tombstone — never `deletedAt`, which this feature does not use).
  final DateTime? tombstonedAt;

  bool get isTransfer => type == ScheduledPaymentType.transfer;
  bool get isDeleted => tombstonedAt != null;

  /// Whether the template still generates future occurrences (feeds HU-04's
  /// "Activos · N" and the active list).
  ///
  /// [onceAlreadyGenerated] must be supplied by the caller (the repository),
  /// since a `once` template has no column of its own recording it fired —
  /// that fact lives in the `ScheduledPaymentOccurrences` ledger as a
  /// `confirmed` row for this template.
  bool isActive({required bool onceAlreadyGenerated}) {
    if (isDeleted) {
      return false;
    }
    if (frequency == ScheduledPaymentFrequency.once && onceAlreadyGenerated) {
      return false;
    }
    final endDate = this.endDate;
    if (endDate != null && nextDate.isAfter(endDate)) {
      return false;
    }
    return true;
  }

  @override
  List<Object?> get props => [
        id,
        accountId,
        categoryId,
        amountMinor,
        currency,
        type,
        note,
        transferAccountId,
        frequency,
        interval,
        firstPaymentDate,
        nextDate,
        endDate,
        requiresConfirmation,
        createdAt,
        updatedAt,
        tombstonedAt,
      ];
}
