import 'dart:async';

import 'package:billetudo/core/error/result.dart';
import 'package:billetudo/features/reports/domain/entities/cashflow_point.dart';
import 'package:billetudo/features/reports/domain/entities/cashflow_series.dart';
import 'package:billetudo/features/reports/domain/entities/chart_history_bounds.dart';
import 'package:billetudo/features/reports/domain/entities/date_range.dart';
import 'package:billetudo/features/reports/domain/usecases/watch_cashflow_report.dart';
import 'package:billetudo/features/reports/presentation/cubit/cashflow_cubit.dart';
import 'package:billetudo/features/reports/presentation/cubit/cashflow_state.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockWatchCashflowReport extends Mock implements WatchCashflowReport {}

void main() {
  late MockWatchCashflowReport watchCashflowReport;

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

  final series = CashflowSeries(
    points: [
      CashflowPoint(
        periodStart: DateTime(2026, 7),
        incomeMinor: 100000,
        expenseMinor: 50000,
        debtIncomeMinor: 0,
        debtExpenseMinor: 0,
      ),
    ],
    includeDebtMovements: true,
    bounds: bounds,
  );

  setUpAll(() {
    registerFallbackValue(
      WatchCashflowReportParams(range: range),
    );
  });

  setUp(() {
    watchCashflowReport = MockWatchCashflowReport();
  });

  blocTest<CashflowCubit, CashflowState>(
    'emits ready with the series once the stream produces a Right',
    build: () {
      when(() => watchCashflowReport(any())).thenAnswer(
        (_) => Stream.value(Right(series)),
      );
      return CashflowCubit(watchCashflowReport);
    },
    act: (cubit) => cubit.load(range: range, includeDebtMovements: true),
    expect: () => [
      const CashflowState(),
      CashflowState(status: CashflowStatus.ready, series: series),
    ],
  );

  blocTest<CashflowCubit, CashflowState>(
    'emits failure when the stream produces a Left',
    build: () {
      when(() => watchCashflowReport(any())).thenAnswer(
        (_) => Stream.value(const Left(UnexpectedFailure('boom'))),
      );
      return CashflowCubit(watchCashflowReport);
    },
    act: (cubit) => cubit.load(range: range, includeDebtMovements: true),
    expect: () => [
      const CashflowState(),
      isA<CashflowState>()
          .having((s) => s.status, 'status', CashflowStatus.failure),
    ],
  );

  test('a second load cancels the previous subscription: no stale emission',
      () async {
    final firstController = StreamController<Result<CashflowSeries>>();
    final secondSeries = series;
    var callCount = 0;
    when(() => watchCashflowReport(any())).thenAnswer((_) {
      callCount++;
      return callCount == 1
          ? firstController.stream
          : Stream.value(Right(secondSeries));
    });

    final cubit = CashflowCubit(watchCashflowReport);
    await cubit.load(range: range, includeDebtMovements: true);
    await cubit.load(range: range, includeDebtMovements: false);
    // The stale first stream must not reach the cubit after it was replaced.
    firstController.add(const Left(UnexpectedFailure('stale')));
    await Future<void>.delayed(Duration.zero);

    expect(cubit.state.status, CashflowStatus.ready);
    expect(cubit.state.series, secondSeries);

    await firstController.close();
    await cubit.close();
  });
}
