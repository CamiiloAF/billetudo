import 'package:billetudo/core/error/result.dart';
import 'package:billetudo/features/reports/domain/entities/chart_history_bounds.dart';
import 'package:billetudo/features/reports/domain/entities/date_range.dart';
import 'package:billetudo/features/reports/domain/entities/net_worth_point.dart';
import 'package:billetudo/features/reports/domain/entities/net_worth_series.dart';
import 'package:billetudo/features/reports/domain/usecases/watch_net_worth_report.dart';
import 'package:billetudo/features/reports/presentation/cubit/net_worth_cubit.dart';
import 'package:billetudo/features/reports/presentation/cubit/net_worth_state.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockWatchNetWorthReport extends Mock implements WatchNetWorthReport {}

void main() {
  late MockWatchNetWorthReport watchNetWorthReport;

  final range = DateRange(
    start: DateTime(2026, 2),
    endExclusive: DateTime(2026, 8),
    granularity: DateGranularity.monthly,
  );

  final bounds = ChartHistoryBounds(
    earliestDataDate: DateTime(2026, 2),
    requestedRange: range,
    effectiveRange: range,
    isClamped: false,
    isDailyGranularity: false,
  );

  final series = NetWorthSeries(
    points: [
      NetWorthPoint(date: DateTime(2026, 7), liquidMinor: 100000, totalMinor: 50000),
    ],
    includeArchivedAccounts: false,
    bounds: bounds,
  );

  setUpAll(() {
    registerFallbackValue(WatchNetWorthReportParams(range: range));
  });

  setUp(() {
    watchNetWorthReport = MockWatchNetWorthReport();
  });

  blocTest<NetWorthCubit, NetWorthState>(
    'emits ready with the series once the stream produces a Right',
    build: () {
      when(() => watchNetWorthReport(any())).thenAnswer(
        (_) => Stream.value(Right(series)),
      );
      return NetWorthCubit(watchNetWorthReport);
    },
    act: (cubit) =>
        cubit.load(range: range, includeArchivedAccounts: false),
    expect: () => [
      const NetWorthState(),
      NetWorthState(status: NetWorthStatus.ready, series: series),
    ],
  );

  blocTest<NetWorthCubit, NetWorthState>(
    'emits failure when the stream produces a Left',
    build: () {
      when(() => watchNetWorthReport(any())).thenAnswer(
        (_) => Stream.value(const Left(UnexpectedFailure('boom'))),
      );
      return NetWorthCubit(watchNetWorthReport);
    },
    act: (cubit) =>
        cubit.load(range: range, includeArchivedAccounts: false),
    expect: () => [
      const NetWorthState(),
      isA<NetWorthState>()
          .having((s) => s.status, 'status', NetWorthStatus.failure),
    ],
  );
}
