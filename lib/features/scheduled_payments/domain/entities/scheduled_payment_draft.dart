import 'package:equatable/equatable.dart';

import '../../../../core/error/result.dart';
import '../../../categories/domain/entities/category.dart' show CategoryKind;
import 'scheduled_payment.dart';

/// Input for creating or editing a scheduled payment template (HU-01/HU-05).
///
/// [categoryKind] is not persisted: it is the `kind` of the category the
/// caller resolved for [categoryId] (the category picker already knows it),
/// carried here only so [validated] can enforce "a category must match the
/// template's money direction" without this feature's domain reaching into
/// Categories' data layer to look it up — same pattern as
/// `transactions/domain/entities/transaction_draft.dart`.
///
/// [tagIds] is only meaningful when [type] is not `transfer` (a transfer
/// never carries tags, criterion 16); `validated()` clears it otherwise.
class ScheduledPaymentDraft extends Equatable {
  const ScheduledPaymentDraft({
    required this.accountId,
    required this.amountMinor,
    required this.currency,
    required this.type,
    required this.frequency,
    required this.nextDate,
    this.id,
    this.categoryId,
    this.categoryKind,
    this.note,
    this.transferAccountId,
    this.interval = 1,
    this.endDate,
    this.requiresConfirmation = false,
    this.tagIds = const <String>[],
  });

  // Field keys, so presentation matches `ValidationFailure.field` without
  // duplicating magic strings.
  static const String fieldId = 'id';
  static const String fieldAccountId = 'accountId';
  static const String fieldAmountMinor = 'amountMinor';
  static const String fieldCurrency = 'currency';
  static const String fieldCategoryId = 'categoryId';
  static const String fieldTransferAccountId = 'transferAccountId';
  static const String fieldInterval = 'interval';
  static const String fieldEndDate = 'endDate';
  static const String fieldNote = 'note';

  static const int maxNoteLength = 500;

  static final RegExp _currencyPattern = RegExp(r'^[A-Z]{3}$');

  /// `null` when creating; the template id when editing.
  final String? id;

  final String accountId;
  final String? categoryId;

  /// The `kind` of the category [categoryId] points to, if any. Required
  /// whenever [categoryId] is set; see class doc.
  final CategoryKind? categoryKind;

  final int amountMinor;
  final String currency;
  final ScheduledPaymentType type;
  final String? note;
  final String? transferAccountId;

  final ScheduledPaymentFrequency frequency;

  /// Ignored (normalized to 1) when [frequency] is `once`.
  final int interval;

  final DateTime nextDate;
  final DateTime? endDate;
  final bool requiresConfirmation;
  final List<String> tagIds;

  /// Validates every business rule of HU-01/HU-05/criterion 16 and returns a
  /// **normalized** draft: trimmed/upper-cased currency, trimmed note (blank
  /// becomes `null`), `interval` forced to 1 for `once`, and
  /// `categoryId`/`transferAccountId`/`tagIds` nulled out where [type]
  /// forbids them.
  ///
  /// Returns `Left(ValidationFailure)` with the offending `field` set, so the
  /// form can highlight it.
  Result<ScheduledPaymentDraft> validated() {
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

    final endDate = this.endDate;
    if (endDate != null && endDate.isBefore(nextDate)) {
      return const Left(
        ValidationFailure(
          'the end date cannot be before the next date',
          field: fieldEndDate,
        ),
      );
    }

    final interval =
        frequency == ScheduledPaymentFrequency.once ? 1 : this.interval;
    if (interval < 1) {
      return const Left(
        ValidationFailure(
          'the interval must be at least 1',
          field: fieldInterval,
        ),
      );
    }

    final typeResult = _validatedByType(accountId: accountId);
    if (typeResult case Left(value: final failure)) {
      return Left(failure);
    }
    final (categoryId, categoryKind, transferAccountId, tagIds) =
        typeResult.getOrElse((_) => (null, null, null, const <String>[]));

    return Right(
      ScheduledPaymentDraft(
        id: id,
        accountId: accountId,
        categoryId: categoryId,
        categoryKind: categoryKind,
        amountMinor: amountMinor,
        currency: currency,
        type: type,
        note: note,
        transferAccountId: transferAccountId,
        frequency: frequency,
        interval: interval,
        nextDate: nextDate,
        endDate: endDate,
        requiresConfirmation: requiresConfirmation,
        tagIds: tagIds,
      ),
    );
  }

  Result<(String?, CategoryKind?, String?, List<String>)> _validatedByType({
    required String accountId,
  }) {
    switch (type) {
      case ScheduledPaymentType.transfer:
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
        // Criterion 16: a transfer is never income nor expense, so it
        // carries no category and no tags.
        return Right((null, null, transferAccountId, const <String>[]));

      case ScheduledPaymentType.expense:
      case ScheduledPaymentType.income:
        final categoryId = this.categoryId;
        if (categoryId != null) {
          final expectedKind = type == ScheduledPaymentType.expense
              ? CategoryKind.expense
              : CategoryKind.income;
          if (categoryKind != expectedKind) {
            return Left(
              ValidationFailure(
                'the category must be of kind ${expectedKind.name}',
                field: fieldCategoryId,
              ),
            );
          }
        }
        return Right((categoryId, categoryKind, null, tagIds));
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
        note,
        transferAccountId,
        frequency,
        interval,
        nextDate,
        endDate,
        requiresConfirmation,
        tagIds,
      ];
}
