import 'package:equatable/equatable.dart';

import 'account.dart';

/// How a movement affects the balance of the account being computed.
///
/// A transfer produces one movement on each side: `transferOut` for the source
/// account and `transferIn` for the destination one.
enum MovementKind { income, expense, transferIn, transferOut }

/// A single transaction as seen **from one account**: the minimum the balance
/// rule needs, with no dependency on the Transactions feature.
class AccountMovement extends Equatable {
  const AccountMovement({
    required this.amountMinor,
    required this.kind,
    this.deletedAt,
  });

  /// Always positive, in cents. The sign comes from [kind].
  final int amountMinor;
  final MovementKind kind;

  /// Soft delete (trash/undo). A deleted movement must never count (HU-04).
  final DateTime? deletedAt;

  bool get isActive => deletedAt == null;

  /// The amount with the sign this account sees.
  int get signedMinor => switch (kind) {
        MovementKind.income || MovementKind.transferIn => amountMinor,
        MovementKind.expense || MovementKind.transferOut => -amountMinor,
      };

  @override
  List<Object?> get props => [amountMinor, kind, deletedAt];
}

/// Derived balance of an account (HU-04) plus the credit figures of a card
/// (HU-02). This is the single source of truth for the rule: the data layer
/// only narrows which rows are read, it never re-implements the arithmetic.
class AccountBalance extends Equatable {
  const AccountBalance._({
    required this.balanceMinor,
    required this.availableCreditMinor,
    required this.overLimit,
    required this.excessMinor,
  });

  /// Balance = opening balance + income + incoming transfers − expenses −
  /// outgoing transfers, **ignoring every soft-deleted movement**.
  factory AccountBalance.fromMovements({
    required Account account,
    required Iterable<AccountMovement> movements,
  }) {
    var balanceMinor = account.initialBalanceMinor;
    for (final movement in movements) {
      if (!movement.isActive) {
        continue;
      }
      balanceMinor += movement.signedMinor;
    }
    return AccountBalance.fromBalance(
      account: account,
      balanceMinor: balanceMinor,
    );
  }

  /// Derives the credit figures from an already computed [balanceMinor].
  factory AccountBalance.fromBalance({
    required Account account,
    required int balanceMinor,
  }) {
    final creditLimitMinor = account.isCard ? account.creditLimitMinor : null;
    if (creditLimitMinor == null) {
      return AccountBalance._(
        balanceMinor: balanceMinor,
        availableCreditMinor: null,
        overLimit: false,
        excessMinor: 0,
      );
    }

    // A card's balance is debt: it is negative. Available credit = limit +
    // balance. When the debt exceeds the limit that sum goes negative, and the
    // remainder is the overspend.
    final remainingMinor = creditLimitMinor + balanceMinor;
    final overLimit = remainingMinor < 0;
    return AccountBalance._(
      balanceMinor: balanceMinor,
      availableCreditMinor: overLimit ? 0 : remainingMinor,
      overLimit: overLimit,
      excessMinor: overLimit ? -remainingMinor : 0,
    );
  }

  /// Current balance in cents. Negative on a card = debt.
  final int balanceMinor;

  /// Available credit in cents, floored at 0 (never negative, HU-04).
  /// `null` when the account is not a card with a limit.
  final int? availableCreditMinor;

  /// Whether the debt exceeds the card's credit limit.
  final bool overLimit;

  /// How much the debt exceeds the limit by, in cents. 0 when not over limit.
  final int excessMinor;

  /// Debt as a positive figure (HU-04 shows the absolute value). 0 when the
  /// balance is not negative.
  int get debtMinor => balanceMinor < 0 ? -balanceMinor : 0;

  @override
  List<Object?> get props => [
        balanceMinor,
        availableCreditMinor,
        overLimit,
        excessMinor,
      ];
}
