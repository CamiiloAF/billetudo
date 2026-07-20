import 'package:equatable/equatable.dart';

/// How a budget is doing over one period window (HU-04). Pure arithmetic on
/// integer cents; the sign of [remainingMinor] tells over- from under-spend.
class BudgetProgress extends Equatable {
  const BudgetProgress({
    required this.amountMinor,
    required this.spentMinor,
    required this.daysLeft,
    this.scheduledMinor = 0,
  });

  /// The budget's assigned amount for the period, in cents.
  final int amountMinor;

  /// Total expense matched to the budget in the window, in cents.
  final int spentMinor;

  /// Whole days left in the window (0 for a closed/past window).
  final int daysLeft;

  /// Projected but not-yet-materialized scheduled-payment expense inside the
  /// window (HU-12): future dates projected from a template's cadence, plus
  /// occurrences already registered as `pending` awaiting confirmation. Never
  /// double-counts a date already in [spentMinor] (that one materialized as a
  /// `Transaction` instead). Always `0` for a past window.
  final int scheduledMinor;

  /// `amountMinor - spentMinor`. Negative when overspent (HU-04).
  int get remainingMinor => amountMinor - spentMinor;

  /// Spent as a fraction of the amount. `0` guards a non-positive amount so the
  /// UI never divides by zero; an amount of 0 with any spend reads as full.
  double get fraction {
    if (amountMinor <= 0) {
      return spentMinor > 0 ? 1 : 0;
    }
    return spentMinor / amountMinor;
  }

  /// Spent as a whole percentage (can exceed 100 when overspent).
  int get percent => (fraction * 100).round();

  /// `spentMinor + scheduledMinor` as a fraction of the amount, same
  /// non-clamped convention as [fraction] (HU-12) — this is *not* what the bar
  /// draws for the "programado" segment, see [scheduledFraction].
  double get committedFraction {
    if (amountMinor <= 0) {
      return spentMinor + scheduledMinor > 0 ? 1 : 0;
    }
    return (spentMinor + scheduledMinor) / amountMinor;
  }

  /// The "programado" segment's own width, as a fraction of the amount,
  /// clamped to whatever room [fraction] left so the spent+programado
  /// segments never overlap past 100% of the bar (HU-12, criterion 5): the
  /// bar draws them contiguous, not stacked.
  double get scheduledFraction {
    if (amountMinor <= 0 || scheduledMinor <= 0) {
      return 0;
    }
    final spentFraction = fraction < 0 ? 0 : fraction;
    final remaining = 1 - spentFraction;
    if (remaining <= 0) {
      return 0;
    }
    final raw = scheduledMinor / amountMinor;
    return raw < remaining ? raw : remaining;
  }

  /// Exclusively driven by [spentMinor] (HU-04, criterion 6): a
  /// spent+programado total past 100% is informative, not a red-flag
  /// overspend — only actual spend is.
  bool get isOverspent => spentMinor > amountMinor;

  @override
  List<Object?> get props => [amountMinor, spentMinor, daysLeft, scheduledMinor];
}
