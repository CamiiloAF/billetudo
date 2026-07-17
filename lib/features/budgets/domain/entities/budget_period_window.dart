import 'package:equatable/equatable.dart';

/// Where a period window sits relative to "today".
enum BudgetWindowStatus { past, current, future }

/// One concrete period of a budget: a half-open date range `[start, endExclusive)`
/// plus its position in the cadence and its state relative to today (HU-05).
///
/// Dates are date-only (midnight); a transaction counts when
/// `start <= tx.date < endExclusive`. [hasPrevious]/[hasNext] encode the
/// navigation bounds (no window before `startDate`, none after `endDate`), which
/// drive the period stepper's disabled chevrons.
class BudgetPeriodWindow extends Equatable {
  const BudgetPeriodWindow({
    required this.start,
    required this.endExclusive,
    required this.index,
    required this.status,
    required this.hasPrevious,
    required this.hasNext,
  });

  /// Inclusive start (date-only).
  final DateTime start;

  /// Exclusive end (date-only): the first instant that no longer belongs to the
  /// window. For a recurring budget it is the next period's start; for a one-off
  /// it is the day after `endDate` (so `endDate` itself is included).
  final DateTime endExclusive;

  /// 0-based index from the `startDate` anchor. 0 is the first period.
  final int index;

  final BudgetWindowStatus status;

  /// Whether a previous/next window exists within the budget's bounds.
  final bool hasPrevious;
  final bool hasNext;

  /// Last day that belongs to the window (inclusive), for display.
  DateTime get lastDay => endExclusive.subtract(const Duration(days: 1));

  bool get isCurrent => status == BudgetWindowStatus.current;

  /// Whole days left from [today] until the window closes, clamped at 0. The day
  /// [today] itself counts as remaining.
  int daysLeftFrom(DateTime today) {
    final from = DateTime(today.year, today.month, today.day);
    final left = endExclusive.difference(from).inDays;
    return left < 0 ? 0 : left;
  }

  @override
  List<Object?> get props => [
        start,
        endExclusive,
        index,
        status,
        hasPrevious,
        hasNext,
      ];
}
