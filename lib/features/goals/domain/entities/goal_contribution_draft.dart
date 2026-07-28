import 'package:equatable/equatable.dart';

import '../../../../core/error/result.dart';
import 'goal_contribution.dart';

/// Input for registering an aporte/retiro (HU-03/HU-04).
///
/// A single shape covers both directions and both "toggle" branches:
///  - Tracking-only ([moveMoney] = `false`): only a [GoalContribution] row is
///    written, `transactionId` stays null, no account/category is needed.
///  - Moves money ([moveMoney] = `true`): a real `transfer` `Transaction` is
///    written too. [originAccountId]/[destinationAccountId] are already
///    resolved by the use case (contribution: origin = the account the user
///    picked, destination = the goal's linked account; withdrawal: origin =
///    the goal's linked account, destination = the account the user picked),
///    so the repository never has to know the goal's own `accountId`.
class GoalContributionDraft extends Equatable {
  const GoalContributionDraft({
    required this.goalId,
    required this.amountMinor,
    required this.direction,
    required this.date,
    required this.currency,
    this.note,
    this.moveMoney = false,
    this.originAccountId,
    this.destinationAccountId,
    this.categoryId,
    this.countsInBudget = false,
  });

  static const String fieldGoalId = 'goalId';
  static const String fieldAmountMinor = 'amountMinor';
  static const String fieldOriginAccountId = 'originAccountId';
  static const String fieldDestinationAccountId = 'destinationAccountId';
  static const String fieldCategoryId = 'categoryId';

  final String goalId;

  /// Always positive; [direction] carries the sign.
  final int amountMinor;

  final GoalMovementDirection direction;
  final DateTime date;

  /// The currency of the resulting movement/transfer (the goal's currency).
  final String currency;

  final String? note;

  /// The "¿Mover dinero de una cuenta?" toggle (HU-03/HU-04).
  final bool moveMoney;

  final String? originAccountId;
  final String? destinationAccountId;

  /// Required only when [countsInBudget] is `true` (HU-03: aporte
  /// presupuestable). Ignored for a tracking-only movement.
  final String? categoryId;

  /// Whether a money-moving transfer counts in presupuestos/reportes (B-3).
  /// Always `false` for a tracking-only movement.
  final bool countsInBudget;

  Result<GoalContributionDraft> validated() {
    if (goalId.trim().isEmpty) {
      return const Left(
        ValidationFailure('a goal is required', field: fieldGoalId),
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

    if (!moveMoney) {
      return Right(
        GoalContributionDraft(
          goalId: goalId,
          amountMinor: amountMinor,
          direction: direction,
          date: date,
          currency: currency,
          note: _blankToNull(note),
        ),
      );
    }

    final originAccountId = _blankToNull(this.originAccountId);
    if (originAccountId == null) {
      return const Left(
        ValidationFailure(
          'an origin account is required to move money',
          field: fieldOriginAccountId,
        ),
      );
    }
    final destinationAccountId = _blankToNull(this.destinationAccountId);
    if (destinationAccountId == null) {
      return const Left(
        ValidationFailure(
          'a destination account is required to move money',
          field: fieldDestinationAccountId,
        ),
      );
    }
    if (originAccountId == destinationAccountId) {
      return const Left(
        ValidationFailure(
          'a movement cannot move money to the same account',
          field: fieldDestinationAccountId,
        ),
      );
    }

    if (countsInBudget && _blankToNull(categoryId) == null) {
      return const Left(
        ValidationFailure(
          'a category is required for a budget-counting movement',
          field: fieldCategoryId,
        ),
      );
    }

    return Right(
      GoalContributionDraft(
        goalId: goalId,
        amountMinor: amountMinor,
        direction: direction,
        date: date,
        currency: currency,
        note: _blankToNull(note),
        moveMoney: true,
        originAccountId: originAccountId,
        destinationAccountId: destinationAccountId,
        categoryId: countsInBudget ? _blankToNull(categoryId) : null,
        countsInBudget: countsInBudget,
      ),
    );
  }

  static String? _blankToNull(String? value) {
    final trimmed = value?.trim();
    return (trimmed == null || trimmed.isEmpty) ? null : trimmed;
  }

  @override
  List<Object?> get props => [
        goalId,
        amountMinor,
        direction,
        date,
        currency,
        note,
        moveMoney,
        originAccountId,
        destinationAccountId,
        categoryId,
        countsInBudget,
      ];
}
