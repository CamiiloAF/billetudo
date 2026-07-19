import 'package:equatable/equatable.dart';

import '../../../../core/error/result.dart';
import 'account.dart';
import 'account_number_edit.dart';

/// Input for creating or editing an account.
///
/// It is separate from [Account] because it carries [numberEdit] in the clear:
/// that value goes to the device's secure storage and **never** reaches Drift
/// or the cloud (HU-03). Everything the user typed lands here; nothing leaves
/// it without going through [validated].
class AccountDraft extends Equatable {
  const AccountDraft({
    required this.name,
    required this.type,
    required this.currency,
    this.id,
    this.initialBalanceMinor = 0,
    this.institution,
    this.numberEdit = const KeepAccountNumber(),
    this.last4,
    this.interestRateBps,
    this.creditLimitMinor,
    this.statementDay,
    this.paymentDueDay,
    this.cardBalancePrimary,
  });

  // Field keys, so presentation matches `ValidationFailure.field` without
  // duplicating magic strings.
  static const String fieldId = 'id';
  static const String fieldName = 'name';
  static const String fieldCurrency = 'currency';
  static const String fieldInstitution = 'institution';
  static const String fieldFullAccountNumber = 'fullAccountNumber';
  static const String fieldLast4 = 'last4';
  static const String fieldInterestRateBps = 'interestRateBps';
  static const String fieldCreditLimitMinor = 'creditLimitMinor';
  static const String fieldStatementDay = 'statementDay';
  static const String fieldPaymentDueDay = 'paymentDueDay';

  static const int maxNameLength = 100;
  static const int maxInstitutionLength = 100;
  static const int minDayOfMonth = 1;
  static const int maxDayOfMonth = 31;

  static final RegExp _currencyPattern = RegExp(r'^[A-Z]{3}$');
  static final RegExp _last4Pattern = RegExp(r'^\d{1,4}$');
  static final RegExp _nonDigits = RegExp(r'\D');

  /// `null` when creating; the account id when editing.
  final String? id;
  final String name;
  final AccountType type;
  final String currency;
  final int initialBalanceMinor;
  final String? institution;

  /// What to do with the number in secure storage (HU-03). Defaults to
  /// [KeepAccountNumber]: omitting it must never erase what is stored.
  final AccountNumberEdit numberEdit;

  /// Manual last 4 digits. Ignored when [numberEdit] sets a full number, since
  /// it is derived from it.
  final String? last4;

  final int? interestRateBps;
  final int? creditLimitMinor;
  final int? statementDay;
  final int? paymentDueDay;
  final CardBalanceView? cardBalancePrimary;

  /// Validates every business rule of HU-01/HU-02/HU-03 and returns a
  /// **normalized** draft: trimmed name, upper-cased currency, derived `last4`,
  /// and card fields nulled out when the type is not a card.
  ///
  /// Returns `Left(ValidationFailure)` with the offending `field` set, so the
  /// form can highlight it.
  Result<AccountDraft> validated() {
    final name = this.name.trim();
    if (name.isEmpty) {
      return const Left(
        ValidationFailure('account name is required', field: fieldName),
      );
    }
    if (name.length > maxNameLength) {
      return const Left(
        ValidationFailure(
          'account name exceeds $maxNameLength characters',
          field: fieldName,
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

    final institution = _blankToNull(this.institution);
    if (institution != null && institution.length > maxInstitutionLength) {
      return const Left(
        ValidationFailure(
          'institution exceeds $maxInstitutionLength characters',
          field: fieldInstitution,
        ),
      );
    }

    final interestRateBps = this.interestRateBps;
    if (interestRateBps != null && interestRateBps < 0) {
      return const Left(
        ValidationFailure(
          'interest rate cannot be negative',
          field: fieldInterestRateBps,
        ),
      );
    }

    final numberResult = _validatedNumber();
    if (numberResult case Left(value: final failure)) {
      return Left(failure);
    }
    final last4 = numberResult.getOrElse((_) => null);

    if (type.isCard) {
      final cardResult = _validatedCardFields();
      if (cardResult case Left(value: final failure)) {
        return Left(failure);
      }
    }

    return Right(
      AccountDraft(
        id: id,
        name: name,
        type: type,
        currency: currency,
        // A card's balance is negated on its way into this draft already
        // (see `AccountFormCubit._buildDraft`): `AccountBalance.fromBalance`
        // treats it as debt, i.e. negative, so nothing left to flip here.
        initialBalanceMinor: initialBalanceMinor,
        institution: institution,
        numberEdit: _normalizedNumberEdit(),
        last4: last4,
        interestRateBps: interestRateBps,
        // HU-01/HU-06: card data only exists on cards. Leaving stale values
        // behind after a type change would corrupt the available-credit rule.
        creditLimitMinor: type.isCard ? creditLimitMinor : null,
        statementDay: type.isCard ? statementDay : null,
        paymentDueDay: type.isCard ? paymentDueDay : null,
        cardBalancePrimary:
            type.isCard ? (cardBalancePrimary ?? CardBalanceView.debt) : null,
      ),
    );
  }

  /// The number this draft would store, if it stores one at all.
  String? get _number => switch (numberEdit) {
        SetAccountNumber(:final value) => _blankToNull(value),
        ClearAccountNumber() || KeepAccountNumber() => null,
      };

  /// Trims the edit down to what it really means. A blank [SetAccountNumber] is
  /// the user emptying the field, which is a deliberate delete;
  /// [KeepAccountNumber] is the only one that survives untouched, because it is
  /// the one protecting a number this draft could not read.
  AccountNumberEdit _normalizedNumberEdit() {
    final number = _number;
    if (number != null) {
      return SetAccountNumber(number);
    }
    return numberEdit is KeepAccountNumber
        ? const KeepAccountNumber()
        : const ClearAccountNumber();
  }

  /// Resolves `last4`: derived from the full number when one is being set,
  /// manual otherwise.
  Result<String?> _validatedNumber() {
    final number = _number;
    if (number != null) {
      if (!type.allowsFullAccountNumber) {
        return Left(
          ValidationFailure(
            type.isCard
                // HU-03: storing a PAN would drag the app into PCI-DSS scope.
                ? 'a credit card cannot store its full number'
                : 'a cash account has no account number',
            field: fieldFullAccountNumber,
          ),
        );
      }
      final digits = number.replaceAll(_nonDigits, '');
      if (digits.isEmpty) {
        return const Left(
          ValidationFailure(
            'account number must contain digits',
            field: fieldFullAccountNumber,
          ),
        );
      }
      return Right(
        digits.length <= 4 ? digits : digits.substring(digits.length - 4),
      );
    }

    final last4 = _blankToNull(this.last4);
    if (last4 != null && !_last4Pattern.hasMatch(last4)) {
      return const Left(
        ValidationFailure('last4 must be 1 to 4 digits', field: fieldLast4),
      );
    }
    return Right(last4);
  }

  Result<Unit> _validatedCardFields() {
    final creditLimitMinor = this.creditLimitMinor;
    if (creditLimitMinor == null) {
      return const Left(
        ValidationFailure(
          'a credit card requires a credit limit',
          field: fieldCreditLimitMinor,
        ),
      );
    }
    if (creditLimitMinor < 0) {
      return const Left(
        ValidationFailure(
          'the credit limit cannot be negative',
          field: fieldCreditLimitMinor,
        ),
      );
    }
    if (!_isDayOfMonth(statementDay)) {
      return const Left(
        ValidationFailure(
          'the statement day must be between $minDayOfMonth and $maxDayOfMonth',
          field: fieldStatementDay,
        ),
      );
    }
    if (!_isDayOfMonth(paymentDueDay)) {
      return const Left(
        ValidationFailure(
          'the payment due day must be between $minDayOfMonth and '
          '$maxDayOfMonth',
          field: fieldPaymentDueDay,
        ),
      );
    }
    return const Right(unit);
  }

  static bool _isDayOfMonth(int? day) =>
      day != null && day >= minDayOfMonth && day <= maxDayOfMonth;

  static String? _blankToNull(String? value) {
    final trimmed = value?.trim();
    return (trimmed == null || trimmed.isEmpty) ? null : trimmed;
  }

  @override
  List<Object?> get props => [
        id,
        name,
        type,
        currency,
        initialBalanceMinor,
        institution,
        numberEdit,
        last4,
        interestRateBps,
        creditLimitMinor,
        statementDay,
        paymentDueDay,
        cardBalancePrimary,
      ];
}
