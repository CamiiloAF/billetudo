import 'package:billetudo/core/error/result.dart';
import 'package:billetudo/features/budgets/domain/entities/zero_based_summary.dart';
import 'package:billetudo/features/budgets/presentation/cubit/zero_based_summary_cubit.dart';
import 'package:billetudo/features/budgets/presentation/cubit/zero_based_summary_state.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'usecase_mocks.dart';

void main() {
  late MockGetZeroBasedSummary getZeroBasedSummary;

  const summary = ZeroBasedSummary(
    currency: 'COP',
    incomeMinor: 500000,
    assignedMinor: 300000,
  );

  setUp(() {
    getZeroBasedSummary = MockGetZeroBasedSummary();
  });

  ZeroBasedSummaryCubit build() => ZeroBasedSummaryCubit(getZeroBasedSummary);

  blocTest<ZeroBasedSummaryCubit, ZeroBasedSummaryState>(
    'HU-06: emits the summary the use case streams',
    setUp: () => when(getZeroBasedSummary.call)
        .thenAnswer((_) => Stream.value(const Right(summary))),
    build: build,
    act: (cubit) => cubit.start(),
    expect: () => [const ZeroBasedSummaryState(summary: summary)],
  );

  blocTest<ZeroBasedSummaryCubit, ZeroBasedSummaryState>(
    'a null payload (nothing to show) clears the hero',
    setUp: () => when(getZeroBasedSummary.call)
        .thenAnswer((_) => Stream.value(const Right(null))),
    build: build,
    act: (cubit) => cubit.start(),
    verify: (cubit) => expect(cubit.state.summary, isNull),
  );

  blocTest<ZeroBasedSummaryCubit, ZeroBasedSummaryState>(
    'a failure keeps the last good value instead of emitting an error state',
    setUp: () => when(getZeroBasedSummary.call).thenAnswer(
      (_) => Stream.fromIterable([
        const Right(summary),
        const Left(DatabaseFailure('boom')),
      ]),
    ),
    build: build,
    act: (cubit) => cubit.start(),
    expect: () => [const ZeroBasedSummaryState(summary: summary)],
  );

  blocTest<ZeroBasedSummaryCubit, ZeroBasedSummaryState>(
    'a new start() cancels the previous subscription instead of stacking',
    setUp: () => when(getZeroBasedSummary.call)
        .thenAnswer((_) => Stream.value(const Right(summary))),
    build: build,
    act: (cubit) async {
      await cubit.start();
      await cubit.start();
    },
    verify: (_) => verify(getZeroBasedSummary.call).called(2),
  );
}
