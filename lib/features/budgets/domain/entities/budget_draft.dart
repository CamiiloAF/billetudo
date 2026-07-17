import 'package:equatable/equatable.dart';

import '../../../../core/error/result.dart';
import 'budget.dart';

/// Input for creating or editing a budget (HU-01/HU-03/HU-09). Carries the
/// user's scope selection as plain id sets; the repository turns those into the
/// join-table rows. Nothing leaves it un-validated: [validated] enforces every
/// business rule and returns a normalized draft.
class BudgetDraft extends Equatable {
  const BudgetDraft({
    required this.name,
    required this.amountMinor,
    required this.currency,
    required this.period,
    required this.startDate,
    required this.recurring,
    this.id,
    this.icon,
    this.endDate,
    this.alertThresholdPct,
    this.rollover = false,
    this.accountIds = const {},
    this.categoryIds = const {},
  });

  static const String fieldName = 'name';
  static const String fieldAmount = 'amountMinor';
  static const String fieldCurrency = 'currency';
  static const String fieldEndDate = 'endDate';
  static const String fieldThreshold = 'alertThresholdPct';

  static const int maxNameLength = 100;
  static const int minThreshold = 1;
  static const int maxThreshold = 100;

  static final RegExp _currencyPattern = RegExp(r'^[A-Z]{3}$');

  /// `null` when creating; the budget id when editing.
  final String? id;
  final String name;
  final String? icon;
  final int amountMinor;
  final String currency;
  final BudgetPeriod period;
  final DateTime startDate;

  /// true = periodic, false = one-off. A one-off is normalized to
  /// `period = custom` in [validated].
  final bool recurring;

  /// Mandatory for a one-off; optional (`null` = forever) for a periodic budget.
  final DateTime? endDate;

  /// null = "don't alert me"; otherwise a whole percent 1-100 (HU-08).
  final int? alertThresholdPct;

  final bool rollover;

  /// Selected account ids. Empty = all accounts (global on that dimension).
  final Set<String> accountIds;

  /// Selected category ids (roots may carry their subcategory ids). Empty = all
  /// expense categories.
  final Set<String> categoryIds;

  bool get isOneOff => !recurring || period == BudgetPeriod.custom;

  /// Validates HU-01/HU-03 and returns a normalized draft: trimmed name,
  /// upper-cased currency, date-only bounds, and one-off coerced to
  /// `custom`/`recurring = false`. `Left(ValidationFailure)` carries the
  /// offending `field` so the form can highlight it.
  Result<BudgetDraft> validated() {
    final name = this.name.trim();
    if (name.isEmpty) {
      return const Left(
        ValidationFailure('budget name is required', field: fieldName),
      );
    }
    if (name.length > maxNameLength) {
      return const Left(
        ValidationFailure(
          'budget name exceeds $maxNameLength characters',
          field: fieldName,
        ),
      );
    }

    if (amountMinor <= 0) {
      return const Left(
        ValidationFailure('amount must be greater than 0', field: fieldAmount),
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

    final threshold = alertThresholdPct;
    if (threshold != null &&
        (threshold < minThreshold || threshold > maxThreshold)) {
      return const Left(
        ValidationFailure(
          'alert threshold must be between $minThreshold and $maxThreshold',
          field: fieldThreshold,
        ),
      );
    }

    final oneOff = isOneOff;
    final start = _dateOnly(startDate);
    final end = endDate == null ? null : _dateOnly(endDate!);

    if (oneOff) {
      if (end == null) {
        return const Left(
          ValidationFailure(
            'a one-off budget requires an end date',
            field: fieldEndDate,
          ),
        );
      }
      if (!end.isAfter(start)) {
        return const Left(
          ValidationFailure(
            'the end date must be after the start date',
            field: fieldEndDate,
          ),
        );
      }
    } else if (end != null && !end.isAfter(start)) {
      return const Left(
        ValidationFailure(
          'the end date must be after the start date',
          field: fieldEndDate,
        ),
      );
    }

    return Right(
      BudgetDraft(
        id: id,
        name: name,
        icon: icon,
        amountMinor: amountMinor,
        currency: currency,
        // A one-off is exactly the `custom` period; a periodic budget never is.
        period: oneOff ? BudgetPeriod.custom : period,
        startDate: start,
        recurring: !oneOff,
        endDate: end,
        alertThresholdPct: threshold,
        rollover: rollover,
        accountIds: accountIds,
        categoryIds: categoryIds,
      ),
    );
  }

  static DateTime _dateOnly(DateTime date) =>
      DateTime(date.year, date.month, date.day);

  @override
  List<Object?> get props => [
        id,
        name,
        icon,
        amountMinor,
        currency,
        period,
        startDate,
        recurring,
        endDate,
        alertThresholdPct,
        rollover,
        accountIds,
        categoryIds,
      ];
}
