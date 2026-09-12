import 'package:equatable/equatable.dart';

import '../../../transactions/domain/entities/transaction.dart';

/// Lifecycle of a [PendingCapture]. Mirrors Drift's `CaptureStatus`, declared
/// here so the domain never depends on the database layer.
///  - `pending`: parsed and waiting in the review inbox. The only actionable
///    state.
///  - `confirmed`: the user accepted it and a real transaction exists
///    ([PendingCapture.transactionId]).
///  - `discarded`: the user rejected it. Reversible until
///    `PurgeDiscardedCaptures` removes the row for good.
enum CaptureStatus { pending, confirmed, discarded }

/// A transaction CANDIDATE parsed from a bank notification (HU-04), waiting
/// in the review inbox.
///
/// **A pending capture is not money.** Nothing here affects a balance, a
/// budget, a goal, a debt, a chart or "disponible para gastar" in any
/// intermediate state — not even while it is rendered as a ghost row in a
/// transaction list. It only becomes a movement when the user confirms it and
/// a real `Transaction` is created (HU-05).
///
/// **Zero retention of notification content** (HU-03): this entity carries no
/// field with the literal notification text and none may ever be added.
/// [merchantRaw] is only the fragment a rule identified as the merchant, and
/// [sourceRuleId] exists so a misbehaving parser can be debugged by rule
/// instead of by keeping the text.
class PendingCapture extends Equatable {
  const PendingCapture({
    required this.id,
    required this.source,
    required this.sourcePackage,
    required this.postedAt,
    required this.amountMinor,
    required this.currency,
    required this.entryType,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    this.sourceRuleId,
    this.merchantRaw,
    this.accountHint,
    this.suggestedAccountId,
    this.suggestedCategoryId,
    this.transactionId,
    this.duplicateOfTransactionId,
  });

  /// UUID as text.
  final String id;

  /// Which capture channel produced this candidate (`notification` today;
  /// voice/OCR reuse the same inbox).
  final TransactionSource source;

  /// Android `packageName` of the issuer app. Identifies the ISSUER, never
  /// its content.
  final String sourcePackage;

  /// Id of the parser rule that produced this row, for debugging.
  final String? sourceRuleId;

  /// When the movement was posted according to the notification.
  final DateTime postedAt;

  /// Always a positive integer of cents. The sign is carried by [entryType],
  /// never by a negative amount.
  final int amountMinor;

  /// ISO-4217 code, e.g. 'COP'.
  final String currency;

  final TransactionType entryType;

  /// Only the fragment identified as the merchant (e.g. `EXITO POBLADO`).
  final String? merchantRaw;

  /// Last 4 digits mentioned by the notification. A hint, never an identity.
  final String? accountHint;

  /// A SUGGESTION resolved from [accountHint]; the user may change it.
  final String? suggestedAccountId;

  /// A SUGGESTION resolved from merchant learning (HU-06).
  final String? suggestedCategoryId;

  final CaptureStatus status;

  /// The real transaction created on confirmation. Null while
  /// pending/discarded.
  final String? transactionId;

  /// A transaction this candidate was found to possibly duplicate (HU-07).
  /// Recorded for the user's benefit only — the app never merges or discards
  /// on its own.
  final String? duplicateOfTransactionId;

  final DateTime createdAt;

  /// Epoch millis, not a `DateTime` — see `_SyncColumns.updatedAt`.
  final int updatedAt;

  bool get isPending => status == CaptureStatus.pending;

  @override
  List<Object?> get props => [
        id,
        source,
        sourcePackage,
        sourceRuleId,
        postedAt,
        amountMinor,
        currency,
        entryType,
        merchantRaw,
        accountHint,
        suggestedAccountId,
        suggestedCategoryId,
        status,
        transactionId,
        duplicateOfTransactionId,
        createdAt,
        updatedAt,
      ];
}
