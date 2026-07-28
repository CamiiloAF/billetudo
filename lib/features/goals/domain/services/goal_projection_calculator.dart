import 'package:injectable/injectable.dart';

import '../entities/goal.dart';
import '../entities/goal_contribution.dart';
import '../entities/goal_projection.dart';

/// Pure domain service implementing HU-05's projection: an estimated arrival
/// date at the current pace, or the monthly contribution needed when there is
/// not enough history to derive a pace.
@lazySingleton
class GoalProjectionCalculator {
  const GoalProjectionCalculator();

  /// [now] is injectable for tests; production callers omit it.
  GoalProjection calculate({
    required Goal goal,
    required List<GoalContribution> contributions,
    required int savedMinor,
    DateTime? now,
  }) {
    final today = now ?? DateTime.now();
    final targetDate = goal.targetDate;

    if (targetDate == null) {
      return const GoalProjection(kind: GoalProjectionKind.noTargetDate);
    }

    if (!targetDate.isAfter(today)) {
      return const GoalProjection(kind: GoalProjectionKind.overdue);
    }

    final remainingMinor = goal.targetMinor - savedMinor;
    final rawMonthsUntilTarget = _monthsBetween(today, targetDate);
    final monthsUntilTarget = rawMonthsUntilTarget < 1 ? 1 : rawMonthsUntilTarget;
    final monthlyNeeded =
        remainingMinor <= 0 ? 0 : (remainingMinor / monthsUntilTarget).ceil();

    // HU-05: "sin historial suficiente" = no movements at all, or the goal
    // has lived less than a month.
    final hasEnoughHistory = contributions.isNotEmpty &&
        !today.isBefore(_addMonths(goal.createdAt, 1));
    if (!hasEnoughHistory) {
      return GoalProjection(
        kind: GoalProjectionKind.insufficientHistory,
        monthlyContributionNeededMinor: monthlyNeeded,
      );
    }

    final pace = _averageNetLast3CompleteMonths(contributions, today: today);
    if (pace <= 0) {
      return GoalProjection(
        kind: GoalProjectionKind.noPace,
        monthlyContributionNeededMinor: monthlyNeeded,
        paceMinorPerMonth: pace,
      );
    }

    if (remainingMinor <= 0) {
      return GoalProjection(
        kind: GoalProjectionKind.projected,
        estimatedDate: today,
        paceMinorPerMonth: pace,
      );
    }

    final monthsToArrival = (remainingMinor / pace).ceil();
    return GoalProjection(
      kind: GoalProjectionKind.projected,
      estimatedDate: _addMonths(today, monthsToArrival),
      paceMinorPerMonth: pace,
    );
  }

  /// The average net (contribution - withdrawal) amount per month over the
  /// last 3 **complete** calendar months before [today] (this month, still in
  /// progress, is excluded).
  int _averageNetLast3CompleteMonths(
    List<GoalContribution> contributions, {
    required DateTime today,
  }) {
    final currentMonthStart = DateTime(today.year, today.month);
    final windowStart = _addMonths(currentMonthStart, -3);
    var total = 0;
    for (final contribution in contributions) {
      final date = contribution.date;
      final monthStart = DateTime(date.year, date.month);
      if (!monthStart.isBefore(windowStart) &&
          monthStart.isBefore(currentMonthStart)) {
        total += contribution.signedMinor;
      }
    }
    return (total / 3).round();
  }

  int _monthsBetween(DateTime from, DateTime to) {
    var months = (to.year - from.year) * 12 + (to.month - from.month);
    if (to.day < from.day) {
      months -= 1;
    }
    return months;
  }

  DateTime _addMonths(DateTime date, int months) {
    final totalMonths = date.month - 1 + months;
    final year = date.year + totalMonths ~/ 12;
    final month = totalMonths % 12 + 1;
    final daysInMonth = DateTime(year, month + 1, 0).day;
    final day = date.day > daysInMonth ? daysInMonth : date.day;
    return DateTime(year, month, day);
  }
}
