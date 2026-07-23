import 'package:equatable/equatable.dart';

import '../../../../core/error/result.dart';
import 'debt.dart';

/// Input for creating or editing a debt (HU-01/HU-05).
///
/// [validated] enforces the business rules and returns a **normalized** draft
/// (trimmed name/counterparty, upper-cased 3-letter currency, blank optionals
/// nulled). The repository only ever persists what already passed it.
class DebtDraft extends Equatable {
  const DebtDraft({
    required this.name,
    required this.direction,
    required this.principalMinor,
    required this.currency,
    this.id,
    this.counterparty,
    this.dueDate,
    this.interestRateBps,
    this.accrualMode = DebtAccrualMode.manual,
  });

  static const String fieldId = 'id';
  static const String fieldName = 'name';
  static const String fieldPrincipalMinor = 'principalMinor';
  static const String fieldCurrency = 'currency';
  static const String fieldInterestRateBps = 'interestRateBps';

  static const int maxNameLength = 100;
  static const int maxCounterpartyLength = 100;

  static final RegExp _currencyPattern = RegExp(r'^[A-Z]{3}$');

  /// null when creating; the debt id when editing.
  final String? id;

  final String name;
  final DebtDirection direction;
  final int principalMinor;
  final String currency;
  final String? counterparty;
  final DateTime? dueDate;
  final int? interestRateBps;
  final DebtAccrualMode accrualMode;

  Result<DebtDraft> validated() {
    final name = this.name.trim();
    if (name.isEmpty) {
      return const Left(
        ValidationFailure('a name is required', field: fieldName),
      );
    }
    if (name.length > maxNameLength) {
      return const Left(
        ValidationFailure(
          'name exceeds $maxNameLength characters',
          field: fieldName,
        ),
      );
    }

    // The opening balance may be 0 (the balance is built from ledger events)
    // but never negative.
    if (principalMinor < 0) {
      return const Left(
        ValidationFailure(
          'the opening balance cannot be negative',
          field: fieldPrincipalMinor,
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

    if (interestRateBps != null && interestRateBps! < 0) {
      return const Left(
        ValidationFailure(
          'the interest rate cannot be negative',
          field: fieldInterestRateBps,
        ),
      );
    }

    final counterparty = _blankToNull(this.counterparty);
    if (counterparty != null && counterparty.length > maxCounterpartyLength) {
      return const Left(
        ValidationFailure(
          'counterparty exceeds $maxCounterpartyLength characters',
          field: fieldName,
        ),
      );
    }

    return Right(
      DebtDraft(
        id: id,
        name: name,
        direction: direction,
        principalMinor: principalMinor,
        currency: currency,
        counterparty: counterparty,
        dueDate: dueDate,
        interestRateBps: interestRateBps,
        accrualMode: accrualMode,
      ),
    );
  }

  static String? _blankToNull(String? value) {
    final trimmed = value?.trim();
    return (trimmed == null || trimmed.isEmpty) ? null : trimmed;
  }

  @override
  List<Object?> get props => [
        id,
        name,
        direction,
        principalMinor,
        currency,
        counterparty,
        dueDate,
        interestRateBps,
        accrualMode,
      ];
}
