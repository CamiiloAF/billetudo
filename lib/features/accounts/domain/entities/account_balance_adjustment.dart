import 'package:equatable/equatable.dart';

import 'account.dart';

/// How a balance adjustment is applied (Mejora #1).
enum BalanceAdjustmentMode {
  /// Creates a dated movement for the difference — it counts as a normal
  /// transaction (reports/budgets). The default the sheet offers.
  registerMovement,

  /// Shifts the account's opening balance so the current figure matches, with
  /// no movement created. Invisible to reports.
  correctInitial,
}

/// Pure calculator for "Ajustar saldo": turns the figure the user typed into
/// the signed difference and the resulting opening balance, keeping every sign
/// rule in one place so neither the cubit nor the widget re-derives it.
///
/// The user types in **displayed** units: a plain account shows its signed
/// balance, but a card shows its debt as a positive figure (see
/// `AccountBalance.debtMinor`), so its real balance is the negation of what was
/// typed. Everything below the conversion is expressed in **real** signed
/// balance, exactly like `AccountBalance.balanceMinor`.
class AccountBalanceAdjustment extends Equatable {
  const AccountBalanceAdjustment._({
    required this.newBalanceMinor,
    required this.diffMinor,
    required this.newInitialBalanceMinor,
  });

  /// Builds the adjustment for [account] from its current real [currentBalanceMinor]
  /// and the [newDisplayedBalanceMinor] the user typed (debt for a card, plain
  /// signed balance otherwise).
  factory AccountBalanceAdjustment.from({
    required Account account,
    required int currentBalanceMinor,
    required int newDisplayedBalanceMinor,
  }) {
    // A card's headline figure is its debt, a positive number, while its real
    // balance is negative — so the typed value is negated back into a real
    // balance here, mirroring `AccountFormCubit`'s `.abs()`/negate round-trip.
    final newBalanceMinor = account.type.isCard
        ? -newDisplayedBalanceMinor.abs()
        : newDisplayedBalanceMinor;
    final diffMinor = newBalanceMinor - currentBalanceMinor;
    return AccountBalanceAdjustment._(
      newBalanceMinor: newBalanceMinor,
      diffMinor: diffMinor,
      // Balance = opening balance + Σ movements, so shifting the opening
      // balance by the difference lands the current balance exactly on target.
      newInitialBalanceMinor: account.initialBalanceMinor + diffMinor,
    );
  }

  /// The target real balance (negative = debt on a card), in cents.
  final int newBalanceMinor;

  /// New balance − current balance, in cents. Signed: positive means the
  /// balance goes up (an income movement, or less debt on a card).
  final int diffMinor;

  /// The opening balance that makes the current balance equal [newBalanceMinor],
  /// in cents. Used by [BalanceAdjustmentMode.correctInitial].
  final int newInitialBalanceMinor;

  /// Whether the typed figure actually differs from the current one.
  bool get hasChange => diffMinor != 0;

  /// The registered movement is an income when the balance grows, an expense
  /// when it shrinks (HU direction is by type, never by a negative amount).
  bool get isIncome => diffMinor > 0;

  @override
  List<Object?> get props => [
        newBalanceMinor,
        diffMinor,
        newInitialBalanceMinor,
      ];
}
