import 'package:billetudo/core/error/result.dart';
import 'package:billetudo/features/reports/domain/entities/category_breakdown.dart';
import 'package:billetudo/features/reports/domain/entities/category_breakdown_item.dart';
import 'package:billetudo/features/reports/domain/entities/date_range.dart';
import 'package:billetudo/features/reports/domain/usecases/watch_category_breakdown_report.dart';
import 'package:billetudo/features/reports/presentation/cubit/category_breakdown_cubit.dart';
import 'package:billetudo/features/reports/presentation/cubit/category_breakdown_state.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockWatchCategoryBreakdownReport extends Mock
    implements WatchCategoryBreakdownReport {}

void main() {
  late MockWatchCategoryBreakdownReport watchCategoryBreakdownReport;

  final range = DateRange(
    start: DateTime(2026, 2),
    endExclusive: DateTime(2026, 8),
    granularity: DateGranularity.monthly,
  );

  final breakdown = CategoryBreakdown(
    items: const [
      CategoryBreakdownItem(
        categoryId: 'cat-1',
        name: 'Mercado',
        amountMinor: 100000,
      ),
    ],
    totalMinor: 100000,
    range: range,
  );

  setUpAll(() {
    registerFallbackValue(WatchCategoryBreakdownReportParams(range: range));
  });

  setUp(() {
    watchCategoryBreakdownReport = MockWatchCategoryBreakdownReport();
  });

  blocTest<CategoryBreakdownCubit, CategoryBreakdownState>(
    'emits ready with the breakdown once the stream produces a Right',
    build: () {
      when(() => watchCategoryBreakdownReport(any())).thenAnswer(
        (_) => Stream.value(Right(breakdown)),
      );
      return CategoryBreakdownCubit(watchCategoryBreakdownReport);
    },
    act: (cubit) => cubit.load(range: range),
    expect: () => [
      const CategoryBreakdownState(),
      CategoryBreakdownState(
        status: CategoryBreakdownStatus.ready,
        breakdown: breakdown,
      ),
    ],
  );

  blocTest<CategoryBreakdownCubit, CategoryBreakdownState>(
    'load forwards accountIds to the usecase params',
    build: () {
      when(() => watchCategoryBreakdownReport(any())).thenAnswer(
        (_) => Stream.value(Right(breakdown)),
      );
      return CategoryBreakdownCubit(watchCategoryBreakdownReport);
    },
    act: (cubit) =>
        cubit.load(range: range, accountIds: const {'acc-1'}),
    verify: (_) {
      verify(
        () => watchCategoryBreakdownReport(
          WatchCategoryBreakdownReportParams(
            range: range,
            accountIds: const {'acc-1'},
          ),
        ),
      ).called(1);
    },
  );
}
