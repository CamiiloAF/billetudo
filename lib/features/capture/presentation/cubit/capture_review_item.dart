import 'package:equatable/equatable.dart';

import '../../../transactions/domain/entities/transaction.dart';
import '../../domain/entities/pending_capture.dart';

/// The already-registered transaction a capture may be duplicating (HU-07),
/// flattened for rendering.
///
/// Built in the cubit rather than read from the entity because the compare
/// strip (`Q1lB88`) needs the transaction's *appearance* — its category icon
/// and color, its account's name — which the duplicate candidate does not
/// carry. It is display data only: nothing here is ever written back, and the
/// strip is deliberately not tappable.
class CaptureDuplicateView extends Equatable {
  const CaptureDuplicateView({
    required this.transactionId,
    required this.amountMinor,
    required this.currency,
    required this.type,
    required this.date,
    this.title,
    this.accountName,
    this.categoryIcon,
    this.categoryColor,
  });

  final String transactionId;
  final int amountMinor;
  final String currency;
  final TransactionType type;
  final DateTime date;

  /// The movement's note. `null` when it has none — the row then falls back
  /// to the category name, and to a neutral label if there is no category
  /// either.
  final String? title;
  final String? accountName;

  /// `Category.icon`/`Category.color` tokens, resolved by
  /// `CategoryAppearance` at paint time.
  final String? categoryIcon;
  final String? categoryColor;

  @override
  List<Object?> get props => [
        transactionId,
        amountMinor,
        currency,
        type,
        date,
        title,
        accountName,
        categoryIcon,
        categoryColor,
      ];
}

/// One row of the review inbox: the capture plus everything the card needs to
/// render that the entity only holds as an id.
///
/// **Still not money.** Resolving an account name here does not attach the
/// capture to that account any more than the entity already suggested it; no
/// balance, budget, goal or chart reads this class.
class CaptureReviewItem extends Equatable {
  const CaptureReviewItem({
    required this.capture,
    this.accountName,
    this.issuerName,
    this.duplicate,
  });

  final PendingCapture capture;

  /// Name of `PendingCapture.suggestedAccountId`, or `null` when the capture
  /// suggests no account (Nu and Nequi never quote the card digits) or the
  /// suggested account no longer exists.
  final String? accountName;

  /// The issuer's brand name from the catalog (`IssuerCatalogEntry`). Falls
  /// back to `null` for a package that left the catalog, in which case the
  /// card hides the "Aviso de X" line rather than printing a package name at
  /// the user.
  final String? issuerName;

  /// Set only for a `DuplicateConfidence.possible` match against an existing
  /// transaction — the card then renders as `EqRlj` instead of `vRWd5`.
  final CaptureDuplicateView? duplicate;

  bool get hasDuplicate => duplicate != null;

  String get id => capture.id;

  @override
  List<Object?> get props => [capture, accountName, issuerName, duplicate];
}
