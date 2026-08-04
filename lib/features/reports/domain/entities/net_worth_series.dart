import 'package:equatable/equatable.dart';

import 'chart_history_bounds.dart';
import 'net_worth_point.dart';

/// The full patrimonio report (HU-02): one [NetWorthPoint] per bucket
/// boundary (N buckets produce N+1 points — one at the start of each bucket
/// plus one at the range's end, so a monthly delta can always be read off two
/// adjacent points), ordered ascending by [NetWorthPoint.date].
class NetWorthSeries extends Equatable {
  const NetWorthSeries({
    required this.points,
    required this.includeArchivedAccounts,
    required this.bounds,
  });

  final List<NetWorthPoint> points;

  /// The toggle value this series was requested with (default `false` —
  /// archived accounts excluded).
  final bool includeArchivedAccounts;

  final ChartHistoryBounds bounds;

  @override
  List<Object?> get props => [points, includeArchivedAccounts, bounds];
}
