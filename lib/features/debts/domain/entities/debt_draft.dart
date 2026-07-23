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
    this.startDate,
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
  static const String fieldStartDate = 'startDate';
  static const String fieldDueDate = 'dueDate';

  static const int maxNameLength = 100;
  static const int maxCounterpartyLength = 100;

  static final RegExp _currencyPattern = RegExp(r'^[A-Z]{3}$');

  /// null when creating; the debt id when editing.
  final String? id;

  final String name;
  final DebtDirection direction;
  final int principalMinor;
  final String currency;

  /// The day the debt started (HU-01). Required in the form (defaults to today
  /// for a new debt) and never in the future. Nullable here only so legacy
  /// callers/tests can omit it; the repository then falls back to the insert's
  /// timestamp. Its calendar day floors every backdated event.
  final DateTime? startDate;

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

    // The opening balance the user typed into the héroe must be greater than 0.
    // (The repository later collapses it to 0 for a registro-inicial debt, but
    // that happens after this validation, on the user's own input.)
    if (principalMinor <= 0) {
      return const Left(
        ValidationFailure(
          'the opening balance must be greater than zero',
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

    // The start date can never be in the future: a debt cannot begin on a day
    // that has not happened yet. Compared by calendar day so "today" always
    // passes regardless of the time component.
    final startDate = this.startDate;
    if (startDate != null) {
      final startDay = DateTime(startDate.year, startDate.month, startDate.day);
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      if (startDay.isAfter(today)) {
        return const Left(
          ValidationFailure(
            'the start date cannot be in the future',
            field: fieldStartDate,
          ),
        );
      }
    }

    // An optional due date must land strictly after the start day (compared by
    // calendar day, so "same day" is rejected). A null due date means "Sin
    // fecha" and is left untouched. When the start date is absent the check
    // falls back to today defensively.
    final dueDate = this.dueDate;
    if (dueDate != null) {
      final baseStart = startDate ?? DateTime.now();
      final startDay =
          DateTime(baseStart.year, baseStart.month, baseStart.day);
      final dueDay = DateTime(dueDate.year, dueDate.month, dueDate.day);
      if (!dueDay.isAfter(startDay)) {
        return const Left(
          ValidationFailure(
            'the due date must be after the start date',
            field: fieldDueDate,
          ),
        );
      }
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
        startDate: startDate,
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
        startDate,
        counterparty,
        dueDate,
        interestRateBps,
        accrualMode,
      ];
}
