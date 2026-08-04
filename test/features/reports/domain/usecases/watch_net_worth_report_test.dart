import 'package:billetudo/core/error/result.dart';
import 'package:billetudo/features/reports/domain/entities/chart_history_bounds.dart';
import 'package:billetudo/features/reports/domain/entities/date_range.dart';
import 'package:billetudo/features/reports/domain/entities/net_worth_series.dart';
import 'package:billetudo/features/reports/domain/usecases/watch_net_worth_report.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'reports_repository_mock.dart';

void main() {
  late MockReportsRepository repository;
  late WatchNetWorthReport usecase;

  final range = DateRange(
    start: DateTime(2026, 1),
    endExclusive: DateTime(2026, 7),
    granularity: DateGranularity.monthly,
  );

  setUp(() {
    repository = MockReportsRepository();
    usecase = WatchNetWorthReport(repository);
  });

  test(
    'defaults `includeArchivedAccounts` to false (HU-02 default: excluded)',
    () {
      final params = WatchNetWorthReportParams(range: range);

      expect(params.includeArchivedAccounts, isFalse);
    },
  );

  test('delegates to the repository with the given params', () {
    final series = NetWorthSeries(
      points: const [],
      includeArchivedAccounts: true,
      bounds: ChartHistoryBounds(
        earliestDataDate: null,
        requestedRange: range,
        effectiveRange: range,
        isClamped: false,
        isDailyGranularity: false,
      ),
    );
    when(
      () => repository.watchNetWorth(
        range: range,
        includeArchivedAccounts: true,
      ),
    ).thenAnswer((_) => Stream.value(Right(series)));

    final result = usecase(
      WatchNetWorthReportParams(range: range, includeArchivedAccounts: true),
    );

    expect(result, emits(Right<Failure, NetWorthSeries>(series)));
  });
}
