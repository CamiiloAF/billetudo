import 'package:billetudo/core/error/result.dart';
import 'package:billetudo/features/reports/domain/entities/category_breakdown.dart';
import 'package:billetudo/features/reports/domain/entities/date_range.dart';
import 'package:billetudo/features/reports/domain/usecases/watch_category_breakdown_report.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'reports_repository_mock.dart';

void main() {
  late MockReportsRepository repository;
  late WatchCategoryBreakdownReport usecase;

  final range = DateRange(
    start: DateTime(2026, 7),
    endExclusive: DateTime(2026, 8),
    granularity: DateGranularity.monthly,
  );

  setUp(() {
    repository = MockReportsRepository();
    usecase = WatchCategoryBreakdownReport(repository);
  });

  test(
    'defaults `accountIds` to empty (todas las cuentas incluidas, criterion 3)',
    () {
      final params = WatchCategoryBreakdownReportParams(range: range);

      expect(params.accountIds, isEmpty);
    },
  );

  test('delegates to the repository with the given range and accountIds', () {
    final breakdown = CategoryBreakdown(
      items: const [],
      totalMinor: 0,
      range: range,
    );
    when(
      () => repository.watchCategoryBreakdown(
        range: range,
        accountIds: const {'acc-1'},
      ),
    ).thenAnswer((_) => Stream.value(Right(breakdown)));

    final result = usecase(
      WatchCategoryBreakdownReportParams(
        range: range,
        accountIds: const {'acc-1'},
      ),
    );

    expect(result, emits(Right<Failure, CategoryBreakdown>(breakdown)));
    verify(
      () => repository.watchCategoryBreakdown(
        range: range,
        accountIds: const {'acc-1'},
      ),
    ).called(1);
  });
}
