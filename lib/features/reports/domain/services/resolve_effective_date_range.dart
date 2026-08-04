import 'package:injectable/injectable.dart';

import '../entities/chart_history_bounds.dart';
import '../entities/date_range.dart';

/// HU-06 "historial insuficiente": pure domain service that resolves a
/// *requested* [DateRange] against the earliest date the user actually has
/// data for, deciding both the clamp and the monthly↔daily granularity
/// switch. No I/O — the caller (the repository) supplies
/// `earliestDataDate`, already read from `watchEarliestDataDate`.
///
/// Rules (docs/requirements/10-graficas-informes.md HU-06):
///  - The view never fakes a longer series than the data supports: if
///    `earliestDataDate` is later than the requested start, the effective
///    range starts there instead, and [ChartHistoryBounds.isClamped] is set.
///  - A short effective span (< [dailyGranularityThresholdDays]) is too
///    coarse to bucket by month — e.g. 3 days of history in a 12-month
///    request would render a single, mostly-empty bar. Below the threshold
///    the granularity switches to daily.
@lazySingleton
class ResolveEffectiveDateRange {
  const ResolveEffectiveDateRange();

  /// Below this many days, buckets switch from monthly to daily. ~2 months:
  /// short enough that a handful of daily bars reads better than 1-2 mostly
  /// empty monthly ones, long enough that a normal multi-month range never
  /// accidentally trips it.
  static const int dailyGranularityThresholdDays = 60;

  ChartHistoryBounds call({
    required DateRange requested,
    required DateTime? earliestDataDate,
  }) {
    var effectiveStart = requested.start;
    if (earliestDataDate != null && earliestDataDate.isAfter(effectiveStart)) {
      effectiveStart = earliestDataDate;
    }
    // Defensive: never let the clamp push the start past the requested end
    // (e.g. all data is newer than an oddly-bounded custom range).
    if (effectiveStart.isAfter(requested.endExclusive)) {
      effectiveStart = requested.endExclusive;
    }

    final isClamped = effectiveStart.isAfter(requested.start);
    final spanDays =
        requested.endExclusive.difference(effectiveStart).inDays;
    final isDaily = spanDays < dailyGranularityThresholdDays;

    final effectiveRange = DateRange(
      start: effectiveStart,
      endExclusive: requested.endExclusive,
      granularity: isDaily ? DateGranularity.daily : DateGranularity.monthly,
    );

    return ChartHistoryBounds(
      earliestDataDate: earliestDataDate,
      requestedRange: requested,
      effectiveRange: effectiveRange,
      isClamped: isClamped,
      isDailyGranularity: isDaily,
    );
  }
}
