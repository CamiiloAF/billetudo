import 'package:equatable/equatable.dart';

/// Granularity of a "stepper" date period (HU-06b): Week / Month / Year,
/// navigated one step at a time. A custom range has no granularity of its
/// own — see [DatePeriodFilter.isCustomRange].
enum DateGranularity { week, month, year }

/// The date filter of HU-06b. There is **no "no filter" state**: the
/// transaction list always shows a bounded period, defaulting to the current
/// month ([DatePeriodFilter.thisMonth]).
///
/// Two shapes, mutually exclusive:
///  - Granular: a [granularity] (week/month/year) anchored on a date within
///    the active period. The stepper ([stepped]) applies immediately.
///  - Custom range ([DatePeriodFilter.custom]): an explicit start/end chosen
///    by the user. Its only way out is clearing it back to "this month"
///    ([clearedToThisMonth]) — there is no bare "no filter" either.
class DatePeriodFilter extends Equatable {
  const DatePeriodFilter._({
    this.granularity,
    this.anchor,
    this.customStart,
    this.customEnd,
  });

  factory DatePeriodFilter.granular(
    DateGranularity granularity,
    DateTime anchor,
  ) =>
      DatePeriodFilter._(granularity: granularity, anchor: _stripTime(anchor));

  /// Default state, always active: the current calendar month.
  factory DatePeriodFilter.thisMonth([DateTime? now]) =>
      DatePeriodFilter.granular(DateGranularity.month, now ?? DateTime.now());

  /// HU-06b: "Rango personalizado". [end] is inclusive (the last day the
  /// user picked); [endExclusive] resolves it to a half-open bound for
  /// queries.
  factory DatePeriodFilter.custom({
    required DateTime start,
    required DateTime end,
  }) {
    final normalizedStart = _stripTime(start);
    final normalizedEnd = _stripTime(end);
    if (normalizedEnd.isBefore(normalizedStart)) {
      throw ArgumentError.value(end, 'end', 'must not be before start');
    }
    return DatePeriodFilter._(
      customStart: normalizedStart,
      customEnd: normalizedEnd,
    );
  }

  /// HU-06b: the "X" on a custom range always lands back on "this month",
  /// never on a bare "no filter".
  static DatePeriodFilter clearedToThisMonth([DateTime? now]) =>
      DatePeriodFilter.thisMonth(now);

  /// `null` when [isCustomRange] is true.
  final DateGranularity? granularity;

  /// Any date within the active granular period. `null` when [isCustomRange]
  /// is true.
  final DateTime? anchor;

  /// Inclusive custom-range bounds. `null` unless this is a custom range.
  final DateTime? customStart;
  final DateTime? customEnd;

  bool get isCustomRange => customStart != null;

  /// Inclusive start of the active period, at midnight.
  DateTime get start =>
      isCustomRange ? customStart! : _periodStart(granularity!, anchor!);

  /// Exclusive end of the active period: the query bound is `date <
  /// endExclusive`, which naturally includes the whole last day regardless of
  /// its time component.
  DateTime get endExclusive => isCustomRange
      ? customEnd!.add(const Duration(days: 1))
      : _periodEndExclusive(granularity!, anchor!);

  /// HU-06b: one [granularity] step per tap (`direction` is `-1` previous,
  /// `1` next), applied immediately — no "Aplicar" needed. Only meaningful on
  /// a granular period; a custom range has nothing to step.
  DatePeriodFilter stepped(int direction) {
    final granularity = this.granularity;
    final anchor = this.anchor;
    if (granularity == null || anchor == null) {
      throw StateError('a custom range has no granularity to step');
    }
    final next = switch (granularity) {
      DateGranularity.week => anchor.add(Duration(days: 7 * direction)),
      DateGranularity.month => DateTime(anchor.year, anchor.month + direction),
      DateGranularity.year => DateTime(anchor.year + direction, anchor.month),
    };
    return DatePeriodFilter.granular(granularity, next);
  }

  /// HU-06b: the granularity segmented control applies immediately, jumping
  /// to the period of [newGranularity] that contains the date currently
  /// active (the custom range's start, if that was the previous state).
  DatePeriodFilter withGranularity(DateGranularity newGranularity) =>
      DatePeriodFilter.granular(
        newGranularity,
        isCustomRange ? customStart! : anchor!,
      );

  static DateTime _stripTime(DateTime date) =>
      DateTime(date.year, date.month, date.day);

  static DateTime _periodStart(DateGranularity granularity, DateTime anchor) =>
      switch (granularity) {
        // ISO week: Monday..Sunday. `weekday` is 1 (Monday)..7 (Sunday).
        DateGranularity.week =>
          anchor.subtract(Duration(days: anchor.weekday - 1)),
        DateGranularity.month => DateTime(anchor.year, anchor.month),
        DateGranularity.year => DateTime(anchor.year),
      };

  static DateTime _periodEndExclusive(
    DateGranularity granularity,
    DateTime anchor,
  ) {
    final start = _periodStart(granularity, anchor);
    return switch (granularity) {
      DateGranularity.week => start.add(const Duration(days: 7)),
      DateGranularity.month => DateTime(start.year, start.month + 1),
      DateGranularity.year => DateTime(start.year + 1),
    };
  }

  @override
  List<Object?> get props => [granularity, anchor, customStart, customEnd];
}
