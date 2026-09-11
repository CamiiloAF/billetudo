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
    required this.accountMatches,
    this.title,
    this.accountName,
    this.categoryName,
    this.categoryIcon,
    this.categoryColor,
  });

  final String transactionId;
  final int amountMinor;
  final String currency;
  final TransactionType type;
  final DateTime date;

  /// Whether [Transaction.accountId] is the account the capture itself
  /// suggests (`TransactionDuplicateCandidate.accountMatches`). Only raises
  /// how the verdict line reads — "misma cuenta" is added when true, dropped
  /// otherwise, never used to rule the candidate in or out.
  final bool accountMatches;

  /// The movement's note. `null` when it has none — the compare strip then
  /// falls back to a neutral label, never to the category name (that has its
  /// own slot now, HU-07).
  final String? title;
  final String? accountName;

  /// The existing transaction's category name, named in text — HU-07 asks
  /// for the category as a comparable fact, not just the color of a glyph.
  final String? categoryName;

  /// `Category.icon`/`Category.color` tokens. Kept for callers that still
  /// need the glyph elsewhere; the compare strip itself no longer paints an
  /// icon wrap (2026-09-09 rebuild).
  final String? categoryIcon;
  final String? categoryColor;

  @override
  List<Object?> get props => [
        transactionId,
        amountMinor,
        currency,
        type,
        date,
        accountMatches,
        title,
        accountName,
        categoryName,
        categoryIcon,
        categoryColor,
      ];
}

/// A capture presented grouped with the wallet/bank counterpart it shares one
/// payment with (HU-07, high-confidence case) — display data only.
///
/// **Never fuses the two rows in the model.** Both `PendingCapture`s stay
/// exactly as they are in the database; this view exists so the Avisos centre
/// can show ONE card instead of two while `PendingCaptureCard.onTap` still
/// dispatches a single capture (the bank side, which carries the real
/// account) to the pre-filled form.
class CaptureGroupView extends Equatable {
  const CaptureGroupView({
    this.merchantRaw,
    this.walletIssuerName,
    this.bankIssuerName,
  });

  /// The wallet counterpart's merchant, when it has one — wallets usually
  /// format it better than the issuing bank. Falls back to the bank
  /// capture's own [PendingCapture.merchantRaw] in the widget when null;
  /// never invented.
  final String? merchantRaw;
  final String? walletIssuerName;
  final String? bankIssuerName;

  @override
  List<Object?> get props => [merchantRaw, walletIssuerName, bankIssuerName];
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
    this.suggestedCategoryName,
    this.duplicate,
    this.group,
  });

  final PendingCapture capture;

  /// Name of `PendingCapture.suggestedAccountId`, or `null` when the capture
  /// suggests no account (Nu and Nequi never quote the card digits) or the
  /// suggested account no longer exists.
  final String? accountName;

  /// Name of `PendingCapture.suggestedCategoryId`, resolved only where the
  /// chip (`oKokr`) renders — `MovementPendingCaptureCard`. `null` both when
  /// there is no suggestion (merchant learning has nothing for this merchant
  /// yet, the common case for a new merchant's first capture) and when the
  /// suggested category no longer exists; either way the chip simply does
  /// not render, never a placeholder.
  final String? suggestedCategoryName;

  /// The issuer's brand name from the catalog (`IssuerCatalogEntry`). Falls
  /// back to `null` for a package that left the catalog, in which case the
  /// card hides the "Aviso de X" line rather than printing a package name at
  /// the user.
  final String? issuerName;

  /// Set only for a `DuplicateConfidence.possible` match against an existing
  /// transaction — the card then renders as `EqRlj` instead of `skjlg`.
  final CaptureDuplicateView? duplicate;

  /// Set only for a `DuplicateConfidence.high` wallet/bank pairing — the card
  /// then renders as `RSizy` instead of `skjlg`. Mutually exclusive with
  /// [duplicate] in practice: a possible-duplicate warning takes priority
  /// when both somehow resolve, because protecting an already-recorded
  /// expense matters more than the grouping convenience.
  final CaptureGroupView? group;

  bool get hasDuplicate => duplicate != null;

  bool get isGrouped => group != null;

  String get id => capture.id;

  @override
  List<Object?> get props => [
        capture,
        accountName,
        issuerName,
        suggestedCategoryName,
        duplicate,
        group,
      ];
}
