import 'package:billetudo/core/error/result.dart';
import 'package:billetudo/features/reports/domain/entities/cashflow_series.dart';
import 'package:billetudo/features/reports/domain/entities/chart_history_bounds.dart';
import 'package:billetudo/features/reports/domain/entities/date_range.dart';
import 'package:billetudo/features/reports/domain/usecases/watch_cashflow_report.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'reports_repository_mock.dart';

void main() {
  late MockReportsRepository repository;
  late WatchCashflowReport usecase;

  final range = DateRange(
    start: DateTime(2026, 1),
    endExclusive: DateTime(2026, 7),
    granularity: DateGranularity.monthly,
  );

  setUp(() {
    repository = MockReportsRepository();
    usecase = WatchCashflowReport(repository);
  });

  test('defaults `includeDebtMovements` to true (HU-01 default: integrated)',
      () {
    final params = WatchCashflowReportParams(range: range);

    expect(params.includeDebtMovements, isTrue);
  });

  test('delegates to the repository with the given params', () {
    final series = CashflowSeries(
      points: const [],
      includeDebtMovements: false,
      bounds: ChartHistoryBounds(
        earliestDataDate: null,
        requestedRange: range,
        effectiveRange: range,
        isClamped: false,
        isDailyGranularity: false,
      ),
    );
    when(
      () => repository.watchCashflow(range: range, includeDebtMovements: false),
    ).thenAnswer((_) => Stream.value(Right(series)));

    final result = usecase(
      WatchCashflowReportParams(range: range, includeDebtMovements: false),
    );

    expect(result, emits(Right<Failure, CashflowSeries>(series)));
    verify(
      () => repository.watchCashflow(range: range, includeDebtMovements: false),
    ).called(1);
  });
}
