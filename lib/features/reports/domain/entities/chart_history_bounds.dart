import 'package:equatable/equatable.dart';

import 'date_range.dart';

/// HU-06 "historial insuficiente": how a requested [DateRange] was resolved
/// against the earliest date with real data, produced by
/// `resolveEffectiveDateRange`.
///
/// The view must never fake a longer series than the data supports: when the
/// user's history is shorter than the requested range, [effectiveRange]
/// clamps the start to [earliestDataDate] and switches to daily granularity,
/// and [isClamped] tells the presentation layer to show the "acotado a lo que
/// existe" note instead of silently drawing a shorter chart.
class ChartHistoryBounds extends Equatable {
  const ChartHistoryBounds({
    required this.earliestDataDate,
    required this.requestedRange,
    required this.effectiveRange,
    required this.isClamped,
    required this.isDailyGranularity,
  });

  /// Null when there is no data at all yet (HU-06 empty state, not this
  /// state's concern to render).
  final DateTime? earliestDataDate;

  /// What the caller asked for.
  final DateRange requestedRange;

  /// What was actually queried: [requestedRange] narrowed so its start never
  /// predates [earliestDataDate], with `effectiveRange.granularity` already
  /// reflecting [isDailyGranularity].
  final DateRange effectiveRange;

  /// True when [effectiveRange].start had to move later than
  /// [requestedRange].start because the user's history does not go back that
  /// far.
  final bool isClamped;

  /// True when [effectiveRange] is short enough that daily buckets (not
  /// monthly) are used — same signal as `effectiveRange.granularity ==
  /// DateGranularity.daily`, kept as its own flag because it is what HU-06
  /// checks to decide whether to show the "historial insuficiente" framing.
  final bool isDailyGranularity;

  @override
  List<Object?> get props => [
        earliestDataDate,
        requestedRange,
        effectiveRange,
        isClamped,
        isDailyGranularity,
      ];
}
