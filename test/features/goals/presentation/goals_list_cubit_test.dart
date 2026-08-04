import 'package:billetudo/core/error/result.dart';
import 'package:billetudo/features/goals/domain/entities/goal_with_progress.dart';
import 'package:billetudo/features/goals/domain/usecases/watch_goals.dart';
import 'package:billetudo/features/goals/presentation/cubit/goals_list_cubit.dart';
import 'package:billetudo/features/goals/presentation/cubit/goals_list_state.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'goals_presentation_fixtures.dart';

class MockWatchGoals extends Mock implements WatchGoals {}

void main() {
  late MockWatchGoals watchGoals;

  setUp(() => watchGoals = MockWatchGoals());

  GoalsListCubit build() => GoalsListCubit(watchGoals);

  blocTest<GoalsListCubit, GoalsListState>(
    'emite loading y luego ready con las metas',
    setUp: () => when(watchGoals.call).thenAnswer(
      (_) => Stream.value(Right([buildGoalWithProgress()])),
    ),
    build: build,
    act: (cubit) => cubit.start(),
    expect: () => [
      isA<GoalsListState>()
          .having((s) => s.status, 'status', GoalsListStatus.loading),
      isA<GoalsListState>()
          .having((s) => s.status, 'status', GoalsListStatus.ready)
          .having((s) => s.goals.length, 'goals', 1)
          .having((s) => s.isEmpty, 'isEmpty', false),
    ],
  );

  blocTest<GoalsListCubit, GoalsListState>(
    'una lista vacía queda ready pero isEmpty',
    setUp: () => when(watchGoals.call)
        .thenAnswer((_) => Stream.value(const Right(<GoalWithProgress>[]))),
    build: build,
    act: (cubit) => cubit.start(),
    skip: 1,
    expect: () => [
      isA<GoalsListState>()
          .having((s) => s.status, 'status', GoalsListStatus.ready)
          .having((s) => s.isEmpty, 'isEmpty', true),
    ],
  );

  blocTest<GoalsListCubit, GoalsListState>(
    'un error del stream lleva a failure con la falla',
    setUp: () => when(watchGoals.call).thenAnswer(
      (_) => Stream.value(const Left(DatabaseFailure('boom'))),
    ),
    build: build,
    act: (cubit) => cubit.start(),
    skip: 1,
    expect: () => [
      isA<GoalsListState>()
          .having((s) => s.status, 'status', GoalsListStatus.failure)
          .having((s) => s.failure, 'failure', isNotNull),
    ],
  );

  blocTest<GoalsListCubit, GoalsListState>(
    'HU-12: dedupea las señales de coherencia por cuenta',
    setUp: () => when(watchGoals.call).thenAnswer(
      (_) => Stream.value(
        Right([
          buildGoalWithProgress(
            goal: buildGoal(id: 'a'),
            coherence: const GoalCoherenceSignal(
              accountId: 'acc-1',
              accountName: 'Cuenta Test',
              totalSavedMinor: 200000,
              accountBalanceMinor: 100000,
              currency: 'COP',
            ),
          ),
          buildGoalWithProgress(
            goal: buildGoal(id: 'b'),
            coherence: const GoalCoherenceSignal(
              accountId: 'acc-1',
              accountName: 'Cuenta Test',
              totalSavedMinor: 200000,
              accountBalanceMinor: 100000,
              currency: 'COP',
            ),
          ),
        ]),
      ),
    ),
    build: build,
    act: (cubit) => cubit.start(),
    skip: 1,
    expect: () => [
      isA<GoalsListState>().having(
        (s) => s.coherenceSignals.length,
        'coherenceSignals',
        1,
      ),
    ],
  );

  group('HU-12: lista filtrada por cuenta (qFX42)', () {
    blocTest<GoalsListCubit, GoalsListState>(
      'filterByAccount scopea la lista a esa cuenta',
      setUp: () => when(watchGoals.call).thenAnswer(
        (_) => Stream.value(
          Right([
            buildGoalWithProgress(goal: buildGoal(id: 'a', accountId: 'acc-1')),
            buildGoalWithProgress(goal: buildGoal(id: 'b', accountId: 'acc-2')),
          ]),
        ),
      ),
      build: build,
      act: (cubit) async {
        await cubit.start();
        cubit.filterByAccount('acc-1', 'Ahorros Bancolombia');
      },
      skip: 2,
      expect: () => [
        isA<GoalsListState>()
            .having((s) => s.isFiltered, 'isFiltered', true)
            .having(
              (s) => s.filterAccountName,
              'filterAccountName',
              'Ahorros Bancolombia',
            )
            .having((s) => s.visibleGoals.length, 'visibleGoals', 1)
            .having(
              (s) => s.visibleGoals.single.goal.id,
              'visibleGoals.single.goal.id',
              'a',
            ),
      ],
    );

    blocTest<GoalsListCubit, GoalsListState>(
      'clearFilter vuelve a mostrar todas las metas',
      setUp: () => when(watchGoals.call).thenAnswer(
        (_) => Stream.value(
          Right([
            buildGoalWithProgress(goal: buildGoal(id: 'a', accountId: 'acc-1')),
            buildGoalWithProgress(goal: buildGoal(id: 'b', accountId: 'acc-2')),
          ]),
        ),
      ),
      build: build,
      act: (cubit) async {
        await cubit.start();
        cubit.filterByAccount('acc-1', 'Ahorros Bancolombia');
        cubit.clearFilter();
      },
      skip: 3,
      expect: () => [
        isA<GoalsListState>()
            .having((s) => s.isFiltered, 'isFiltered', false)
            .having((s) => s.filterAccountId, 'filterAccountId', isNull)
            .having((s) => s.visibleGoals.length, 'visibleGoals', 2),
      ],
    );
  });
}
