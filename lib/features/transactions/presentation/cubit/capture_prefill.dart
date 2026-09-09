import 'package:equatable/equatable.dart';

import '../../domain/entities/transaction.dart';

/// What a pending capture hands to the ordinary transaction form when the
/// user dispatches it (HU-05).
///
/// Confirming a capture is never a screen of its own with rules of its own:
/// it is **this** form, pre-filled, going through the very same validation a
/// manually typed movement goes through — so a capture can never register
/// something the form would have rejected. Everything here is a suggestion
/// the user can overwrite before saving.
///
/// [captureId] is what turns the save into a confirmation rather than a
/// plain creation: the cubit routes it through `ConfirmPendingCapture`, which
/// forces `source = notification`, links the capture to the movement it
/// became, and feeds the merchant/category learning of HU-06.
class CapturePrefill extends Equatable {
  const CapturePrefill({
    required this.captureId,
    required this.amountMinor,
    required this.currency,
    required this.type,
    required this.postedAt,
    this.accountId,
    this.note,
    this.categoryId,
  });

  final String captureId;
  final int amountMinor;
  final String currency;
  final TransactionType type;

  /// The moment the issuer said the movement was posted — the form's date.
  final DateTime postedAt;

  /// `PendingCapture.suggestedAccountId`. `null` falls back to the form's own
  /// default account, exactly as a manual movement would.
  final String? accountId;

  /// The merchant fragment the parser identified, used to seed the note. The
  /// literal notification text is never available here and never will be
  /// (zero retention, HU-03).
  final String? note;

  /// `PendingCapture.suggestedCategoryId`, learned from previous
  /// confirmations of the same merchant (HU-06). Still only a suggestion:
  /// the category picker opens on it and the user may change it.
  final String? categoryId;

  @override
  List<Object?> get props => [
        captureId,
        amountMinor,
        currency,
        type,
        postedAt,
        accountId,
        note,
        categoryId,
      ];
}
