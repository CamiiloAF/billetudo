import 'package:billetudo/core/error/result.dart';
import 'package:billetudo/features/reports/domain/entities/reports_dashboard.dart';
import 'package:billetudo/features/reports/domain/usecases/watch_reports_dashboard.dart';
import 'package:billetudo/features/reports/presentation/cubit/reports_dashboard_cubit.dart';
import 'package:billetudo/features/reports/presentation/cubit/reports_dashboard_state.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockWatchReportsDashboard extends Mock implements WatchReportsDashboard {}

void main() {
  late MockWatchReportsDashboard watchReportsDashboard;

  const dashboard = ReportsDashboard(budgets: [], goals: []);

  setUp(() {
    watchReportsDashboard = MockWatchReportsDashboard();
  });

  blocTest<ReportsDashboardCubit, ReportsDashboardState>(
    'emits ready with the dashboard once the stream produces a Right',
    build: () {
      when(() => watchReportsDashboard()).thenAnswer(
        (_) => Stream.value(const Right(dashboard)),
      );
      return ReportsDashboardCubit(watchReportsDashboard);
    },
    act: (cubit) => cubit.start(),
    expect: () => [
      const ReportsDashboardState(),
      const ReportsDashboardState(
        status: ReportsDashboardStatus.ready,
        dashboard: dashboard,
      ),
    ],
  );

  blocTest<ReportsDashboardCubit, ReportsDashboardState>(
    'emits failure when the stream produces a Left',
    build: () {
      when(() => watchReportsDashboard()).thenAnswer(
        (_) => Stream.value(const Left(UnexpectedFailure('boom'))),
      );
      return ReportsDashboardCubit(watchReportsDashboard);
    },
    act: (cubit) => cubit.start(),
    expect: () => [
      const ReportsDashboardState(),
      isA<ReportsDashboardState>().having(
        (s) => s.status,
        'status',
        ReportsDashboardStatus.failure,
      ),
    ],
  );
}
