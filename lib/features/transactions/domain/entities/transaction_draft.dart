import 'package:equatable/equatable.dart';

import '../../../../core/error/result.dart';
import '../../../categories/domain/entities/category.dart' show CategoryKind;
import 'transaction.dart';

/// Input for creating or editing a transaction (HU-01/02/03/04).
///
/// [categoryKind] is not persisted: it is the `kind` of the category the
/// caller resolved for [categoryId] (the category picker already knows it),
/// carried here only so [validated] can enforce "a category must match the
/// transaction's money direction" without this feature's domain reaching into
/// Categories' data layer to look it up.
///
/// [source] is only honoured by `TransactionRepository.createTransaction`.
/// `updateTransaction` never touches it: the capture origin is a historical
/// fact, not something a manual edit can rewrite (HU-04).
class TransactionDraft extends Equatable {
  const TransactionDraft({
    required this.accountId,
    required this.amountMinor,
    required this.currency,
    required this.type,
    required this.date,
    this.id,
    this.categoryId,
    this.categoryKind,
    this.note,
    this.transferAccountId,
    this.source = TransactionSource.manual,
    this.scheduledPaymentId,
    this.goalId,
    this.debtId,
  });

  // Field keys, so presentation matches `ValidationFailure.field` without
  // duplicating magic strings.
  static const String fieldId = 'id';
  static const String fieldAccountId = 'accountId';
  static const String fieldAmountMinor = 'amountMinor';
  static const String fieldCurrency = 'currency';
  static const String fieldCategoryId = 'categoryId';
  static const String fieldTransferAccountId = 'transferAccountId';
  static const String fieldNote = 'note';

  static const int maxNoteLength = 500;

  static final RegExp _currencyPattern = RegExp(r'^[A-Z]{3}$');

  /// `null` when creating; the transaction id when editing.
  final String? id;

  final String accountId;
  final String? categoryId;

  /// The `kind` of the category [categoryId] points to, if any. Required
  /// whenever [categoryId] is set; see class doc.
  final CategoryKind? categoryKind;

  final int amountMinor;
  final String currency;
  final TransactionType type;
  final DateTime date;
  final String? note;
  final TransactionSource source;

  final String? transferAccountId;
  final String? scheduledPaymentId;
  final String? goalId;
  final String? debtId;

  /// Validates every business rule of HU-01/HU-02/HU-03/HU-04 and returns a
  /// **normalized** draft: trimmed/upper-cased currency, trimmed note (blank
  /// becomes `null`), and `categoryId`/`transferAccountId`/links nulled out
  /// where [type] forbids them.
  ///
  /// Returns `Left(ValidationFailure)` with the offending `field` set, so the
  /// form can highlight it.
  Result<TransactionDraft> validated() {
    final accountId = this.accountId.trim();
    if (accountId.isEmpty) {
      return const Left(
        ValidationFailure('an account is required', field: fieldAccountId),
      );
    }

    if (amountMinor <= 0) {
      return const Left(
        ValidationFailure(
          'the amount must be a positive integer of cents',
          field: fieldAmountMinor,
        ),
      );
    }

    final currency = this.currency.trim().toUpperCase();
    if (!_currencyPattern.hasMatch(currency)) {
      return const Left(
        ValidationFailure(
          'currency must be a 3-letter ISO-4217 code',
          field: fieldCurrency,
        ),
      );
    }

    final note = _blankToNull(this.note);
    if (note != null && note.length > maxNoteLength) {
      return const Left(
        ValidationFailure(
          'note exceeds $maxNoteLength characters',
          field: fieldNote,
        ),
      );
    }

    final typeResult = _validatedByType(accountId: accountId);
    if (typeResult case Left(value: final failure)) {
      return Left(failure);
    }
    final (categoryId, categoryKind, transferAccountId) =
        typeResult.getOrElse((_) => (null, null, null));

    return Right(
      TransactionDraft(
        id: id,
        accountId: accountId,
        categoryId: categoryId,
        categoryKind: categoryKind,
        amountMinor: amountMinor,
        currency: currency,
        type: type,
        date: date,
        note: note,
        source: source,
        transferAccountId: transferAccountId,
        scheduledPaymentId: scheduledPaymentId,
        goalId: goalId,
        debtId: debtId,
      ),
    );
  }

  Result<(String?, CategoryKind?, String?)> _validatedByType({
    required String accountId,
  }) {
    switch (type) {
      case TransactionType.transfer:
        final transferAccountId = this.transferAccountId;
        if (transferAccountId == null || transferAccountId.trim().isEmpty) {
          return const Left(
            ValidationFailure(
              'a transfer requires a destination account',
              field: fieldTransferAccountId,
            ),
          );
        }
        if (transferAccountId == accountId) {
          return const Left(
            ValidationFailure(
              'a transfer cannot move money to the same account',
              field: fieldTransferAccountId,
            ),
          );
        }
        // HU-03: a transfer is never income nor expense, so it carries no
        // category.
        return Right((null, null, transferAccountId));

      case TransactionType.expense:
      case TransactionType.income:
        final categoryId = this.categoryId;
        final expectedKind = type == TransactionType.expense
            ? CategoryKind.expense
            : CategoryKind.income;
        if (categoryId == null) {
          return const Left(
            ValidationFailure(
              'a category is required',
              field: fieldCategoryId,
            ),
          );
        }
        if (categoryKind != expectedKind) {
          return Left(
            ValidationFailure(
              'the category must be of kind ${expectedKind.name}',
              field: fieldCategoryId,
            ),
          );
        }
        return Right((categoryId, categoryKind, null));
    }
  }

  static String? _blankToNull(String? value) {
    final trimmed = value?.trim();
    return (trimmed == null || trimmed.isEmpty) ? null : trimmed;
  }

  @override
  List<Object?> get props => [
        id,
        accountId,
        categoryId,
        categoryKind,
        amountMinor,
        currency,
        type,
        date,
        note,
        source,
        transferAccountId,
        scheduledPaymentId,
        goalId,
        debtId,
      ];
}
