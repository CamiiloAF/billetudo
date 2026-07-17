import '../entities/budget.dart';
import '../entities/budget_period_window.dart';

/// Turns a budget's anchor + cadence into concrete [BudgetPeriodWindow]s
/// (HU-03/HU-05). Pure and deterministic: no clock beyond the `now` it is
/// handed, no I/O. This is the single source of truth for period math, and the
/// most delicate piece of the feature — cover it with tests.
///
/// Conventions:
///  - Windows are date-only, half-open `[start, endExclusive)`. Index 0 starts
///    exactly at `startDate`; positive indices move forward, there is no
///    negative index (you cannot go before the anchor, HU-05).
///  - `weekly`/`monthly`/`yearly` advance in whole blocks from the anchor.
///  - `biweekly` is the es-CO **semi-monthly** fortnight: two cuts per month at
///    day `d` and day `((d + 15 - 1) % 30) + 1` (d + 15 wrapped into 1..30), each
///    clamped to the month's last day. Anchor 1 -> `1–15` / `16–end`; anchor 21
///    -> `21–5` / `6–20`. NOT a rolling 14 days.
///  - `custom` / any non-recurring budget is a single window
///    `[startDate, endDate]` (end inclusive), with no navigation past its edges.
class BudgetPeriodCalculator {
  BudgetPeriodCalculator(this.budget)
      : _anchor = _dateOnly(budget.startDate),
        _end = budget.endDate == null ? null : _dateOnly(budget.endDate!);

  final Budget budget;
  final DateTime _anchor;
  final DateTime? _end;

  /// The window that contains "today", clamped to the budget's bounds: a budget
  /// whose anchor is in the future shows its first window; one already past its
  /// `endDate` shows its last. This is the stepper's default (HU-05).
  BudgetPeriodWindow currentWindow(DateTime now) {
    final today = _dateOnly(now);
    final maxIndex = _maxIndex();

    if (today.isBefore(_anchor)) {
      return windowAt(0, now);
    }
    if (maxIndex != null) {
      final maxWindowEnd = _endExclusiveOf(maxIndex);
      if (!today.isBefore(maxWindowEnd)) {
        return windowAt(maxIndex, now);
      }
    }

    // Walk forward from the anchor until the window contains today. Bounded by
    // construction: each step advances at least ~7 days.
    var index = 0;
    while (!today.isBefore(_endExclusiveOf(index))) {
      index++;
    }
    return windowAt(index, now);
  }

  /// The window at [index] (0-based from the anchor), with its status against
  /// [now] and its navigation flags. Callers must keep [index] within
  /// `0..maxIndex`.
  BudgetPeriodWindow windowAt(int index, DateTime now) {
    final start = _startOf(index);
    final endExclusive = _endExclusiveOf(index);
    final today = _dateOnly(now);
    final maxIndex = _maxIndex();

    return BudgetPeriodWindow(
      start: start,
      endExclusive: endExclusive,
      index: index,
      status: _statusOf(start, endExclusive, today),
      hasPrevious: index > 0,
      hasNext: !budget.isOneOff && (maxIndex == null || index < maxIndex),
    );
  }

  BudgetWindowStatus _statusOf(
    DateTime start,
    DateTime endExclusive,
    DateTime today,
  ) {
    if (today.isBefore(start)) {
      return BudgetWindowStatus.future;
    }
    if (!today.isBefore(endExclusive)) {
      return BudgetWindowStatus.past;
    }
    return BudgetWindowStatus.current;
  }

  /// Largest navigable index, or `null` when the budget renews forever. A
  /// one-off is always a single window (index 0). A periodic budget with an
  /// `endDate` stops at the window that still starts on or before it.
  int? _maxIndex() {
    if (budget.isOneOff) {
      return 0;
    }
    final end = _end;
    if (end == null) {
      return null;
    }
    var index = 0;
    while (!_startOf(index + 1).isAfter(end)) {
      index++;
    }
    return index;
  }

  DateTime _startOf(int index) {
    if (budget.isOneOff) {
      return _anchor;
    }
    return switch (budget.period) {
      BudgetPeriod.weekly => _anchor.add(Duration(days: 7 * index)),
      BudgetPeriod.monthly => _monthAnchor(index),
      BudgetPeriod.yearly => _yearAnchor(index),
      BudgetPeriod.biweekly => _biweeklyCut(index),
      // custom is always one-off, handled above; kept exhaustive.
      BudgetPeriod.custom => _anchor,
    };
  }

  DateTime _endExclusiveOf(int index) {
    if (budget.isOneOff) {
      // One-off: [startDate, endDate] with the end day included. When no endDate
      // is set (defensive; validation requires one), fall back to the anchor.
      final end = _end ?? _anchor;
      return end.add(const Duration(days: 1));
    }
    return _startOf(index + 1);
  }

  /// Monthly anchored to the start day-of-month, clamping to the last day for
  /// months that lack it (e.g. anchor 31 -> Feb 28/29).
  DateTime _monthAnchor(int index) =>
      _clampedDate(_anchor.year, _anchor.month + index, _anchor.day);

  /// Yearly anchored to the start month/day, clamping Feb 29 to Feb 28 in
  /// non-leap years.
  DateTime _yearAnchor(int index) =>
      _clampedDate(_anchor.year + index, _anchor.month, _anchor.day);

  /// Semi-monthly cut at [index]. See the class doc for the day-number rule.
  DateTime _biweeklyCut(int index) {
    final d = _anchor.day;
    final cutB = ((d + 15 - 1) % 30) + 1;
    final lo = d < cutB ? d : cutB;
    final hi = d < cutB ? cutB : d;
    final anchorIsLo = d == lo;

    final int monthOffset;
    final int dayNum;
    if (anchorIsLo) {
      // Anchor is the earlier cut of its month: even index -> lo, odd -> hi.
      monthOffset = _floorDiv(index, 2);
      dayNum = _floorMod(index, 2) == 0 ? lo : hi;
    } else {
      // Anchor is the later cut: even index -> hi, odd -> lo (of the next month).
      monthOffset = _floorDiv(index + 1, 2);
      dayNum = _floorMod(index, 2) == 0 ? hi : lo;
    }
    return _clampedDate(_anchor.year, _anchor.month + monthOffset, dayNum);
  }

  /// A date with [day] clamped to the last day of the (possibly overflowing)
  /// month. `DateTime(y, m + n)` normalizes month overflow/underflow for us.
  static DateTime _clampedDate(int year, int month, int day) {
    final firstOfMonth = DateTime(year, month);
    final lastDay = DateTime(firstOfMonth.year, firstOfMonth.month + 1, 0).day;
    return DateTime(
      firstOfMonth.year,
      firstOfMonth.month,
      day < lastDay ? day : lastDay,
    );
  }

  static DateTime _dateOnly(DateTime date) =>
      DateTime(date.year, date.month, date.day);

  static int _floorDiv(int a, int b) => (a - _floorMod(a, b)) ~/ b;

  static int _floorMod(int a, int b) => ((a % b) + b) % b;
}
