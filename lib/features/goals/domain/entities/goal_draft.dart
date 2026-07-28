import 'package:equatable/equatable.dart';

import '../../../../core/error/result.dart';

/// Input for creating or editing a goal (HU-01/HU-02/HU-08).
///
/// [validated] enforces the business rules and returns a **normalized** draft
/// (trimmed name, upper-cased 3-letter currency). The repository only ever
/// persists what already passed it.
class GoalDraft extends Equatable {
  const GoalDraft({
    required this.name,
    required this.targetMinor,
    required this.currency,
    this.id,
    this.accountId,
    this.targetDate,
    this.icon,
    this.initialSavedMinor,
  });

  static const String fieldId = 'id';
  static const String fieldName = 'name';
  static const String fieldTargetMinor = 'targetMinor';
  static const String fieldCurrency = 'currency';
  static const String fieldTargetDate = 'targetDate';
  static const String fieldInitialSavedMinor = 'initialSavedMinor';

  static const int maxNameLength = 100;

  static final RegExp _currencyPattern = RegExp(r'^[A-Z]{3}$');

  /// `null` when creating; the goal id when editing.
  final String? id;

  final String name;

  /// Objective amount in cents. Must be > 0.
  final int targetMinor;

  final String currency;

  /// Optional account this goal is tied to (HU-02). Existence and
  /// tombstone-freeness are checked by the use case against the accounts
  /// repository, not here — this draft has no data-layer access.
  final String? accountId;

  final DateTime? targetDate;
  final String? icon;

  /// HU-01: an already-existing amount the user declares when creating the
  /// goal. Only meaningful for `CreateGoal`; ignored by `UpdateGoal`. When
  /// set, it becomes the first `GoalContribution` (never a stored value).
  final int? initialSavedMinor;

  /// Validates the shared field rules. [requireFutureTargetDate] is `true`
  /// only for creation (HU-01: "posterior a hoy al crear"); editing an
  /// existing goal never re-validates a `targetDate` that has since passed
  /// (HU-05 explicitly allows an overdue goal to keep existing peacefully).
  Result<GoalDraft> validated({bool requireFutureTargetDate = false}) {
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

    if (targetMinor <= 0) {
      return const Left(
        ValidationFailure(
          'the target amount must be greater than zero',
          field: fieldTargetMinor,
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

    final targetDate = this.targetDate;
    if (requireFutureTargetDate && targetDate != null) {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final targetDay =
          DateTime(targetDate.year, targetDate.month, targetDate.day);
      if (!targetDay.isAfter(today)) {
        return const Left(
          ValidationFailure(
            'the target date must be after today',
            field: fieldTargetDate,
          ),
        );
      }
    }

    final initialSavedMinor = this.initialSavedMinor;
    if (initialSavedMinor != null && initialSavedMinor < 0) {
      return const Left(
        ValidationFailure(
          'the starting progress cannot be negative',
          field: fieldInitialSavedMinor,
        ),
      );
    }

    final accountId = _blankToNull(this.accountId);

    return Right(
      GoalDraft(
        id: id,
        name: name,
        targetMinor: targetMinor,
        currency: currency,
        accountId: accountId,
        targetDate: targetDate,
        icon: _blankToNull(icon),
        initialSavedMinor: initialSavedMinor,
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
        targetMinor,
        currency,
        accountId,
        targetDate,
        icon,
        initialSavedMinor,
      ];
}
