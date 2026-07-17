import 'package:equatable/equatable.dart';

/// How a budget is doing over one period window (HU-04). Pure arithmetic on
/// integer cents; the sign of [remainingMinor] tells over- from under-spend.
class BudgetProgress extends Equatable {
  const BudgetProgress({
    required this.amountMinor,
    required this.spentMinor,
    required this.daysLeft,
  });

  /// The budget's assigned amount for the period, in cents.
  final int amountMinor;

  /// Total expense matched to the budget in the window, in cents.
  final int spentMinor;

  /// Whole days left in the window (0 for a closed/past window).
  final int daysLeft;

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

  bool get isOverspent => spentMinor > amountMinor;

  @override
  List<Object?> get props => [amountMinor, spentMinor, daysLeft];
}
