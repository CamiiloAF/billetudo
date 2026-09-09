import 'package:equatable/equatable.dart';

import '../../../categories/domain/entities/category.dart' show CategoryKind;
import '../../../transactions/domain/entities/transaction.dart'
    show TransactionType;

/// A field the parser managed to fill from the transcription. Used by the
/// presentation layer to tell apart what the app *inferred* from what the
/// user confirmed (HU-05).
enum SpokenField { amount, type, category, account, date, note }

/// The outcome of parsing one dictated phrase.
///
/// Every field is optional on purpose: **partial parsing is the common case,
/// not the exception** (HU-05). A draft that only carries an amount is a
/// partial success and still opens the form prefilled; only the absence of an
/// amount makes the capture unusable on its own, and even then the form opens
/// with whatever else was understood.
///
/// [amountMinor] is a positive integer of minor units (cents). The direction
/// of the movement is [type]'s job — never a negative amount.
class SpokenTransactionDraft extends Equatable {
  const SpokenTransactionDraft({
    required this.transcript,
    this.amountMinor,
    this.amountIsUncertain = false,
    this.type,
    this.categoryId,
    this.categoryName,
    this.categoryKind,
    this.accountId,
    this.accountName,
    this.date,
    this.note,
  })  : assert(
          amountMinor == null || amountMinor > 0,
          'amountMinor is always a positive integer of cents',
        ),
        assert(
          type != TransactionType.transfer,
          'voice never produces transfers (product decision, HU-01)',
        );

  /// What the recognizer heard, verbatim. Kept so the flow can always show it
  /// back to the user; it is never persisted as a record of its own.
  final String transcript;

  /// Positive integer of minor units, or `null` when no amount was found.
  final int? amountMinor;

  /// True when [amountMinor] came out of the magnitude-elision heuristic
  /// ("gasté veinte" -> 20.000) rather than from something the user said
  /// explicitly. The flow must surface it for confirmation instead of
  /// treating it as a fact.
  final bool amountIsUncertain;

  /// `expense` or `income`, or `null` when no polarity verb was recognized —
  /// in which case the form keeps its own default rather than the parser
  /// inventing one. Never `transfer`.
  final TransactionType? type;

  final String? categoryId;
  final String? categoryName;
  final CategoryKind? categoryKind;

  final String? accountId;
  final String? accountName;

  /// Date-only (midnight local). Never in the future: a future date means a
  /// scheduled payment, not a transaction (HU-04d).
  final DateTime? date;

  /// What was left over after every other field was extracted, cleaned of
  /// command fillers. `null` when nothing meaningful remained.
  final String? note;

  bool get hasAmount => amountMinor != null;

  /// The fields the app inferred, so the UI can mark them as suggestions.
  Set<SpokenField> get filledFields => <SpokenField>{
        if (amountMinor != null) SpokenField.amount,
        if (type != null) SpokenField.type,
        if (categoryId != null) SpokenField.category,
        if (accountId != null) SpokenField.account,
        if (date != null) SpokenField.date,
        if (note != null && note!.isNotEmpty) SpokenField.note,
      };

  /// True when nothing at all could be extracted. Still opens the form (HU-05,
  /// "cero-campos-entendidos también abre el formulario").
  bool get isEmpty => filledFields.isEmpty;

  @override
  List<Object?> get props => [
        transcript,
        amountMinor,
        amountIsUncertain,
        type,
        categoryId,
        categoryName,
        categoryKind,
        accountId,
        accountName,
        date,
        note,
      ];
}
