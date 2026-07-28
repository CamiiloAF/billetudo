import 'package:billetudo/core/error/result.dart';
import 'package:billetudo/features/goals/domain/entities/goal_contribution.dart';
import 'package:billetudo/features/goals/domain/entities/goal_detail.dart';
import 'package:billetudo/features/goals/domain/entities/goal_momentum.dart';
import 'package:billetudo/features/goals/domain/entities/goal_projection.dart';
import 'package:billetudo/features/goals/domain/usecases/archive_goal.dart';
import 'package:billetudo/features/goals/domain/usecases/contribute_to_goal.dart';
import 'package:billetudo/features/goals/domain/usecases/delete_goal.dart';
import 'package:billetudo/features/goals/domain/usecases/watch_goal_detail.dart';
import 'package:billetudo/features/goals/presentation/cubit/goal_detail_cubit.dart';
import 'package:billetudo/features/goals/presentation/cubit/goal_detail_state.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'goals_presentation_fixtures.dart';

class MockWatchGoalDetail extends Mock implements WatchGoalDetail {}

class MockArchiveGoal extends Mock implements ArchiveGoal {}

class MockDeleteGoal extends Mock implements DeleteGoal {}

class MockContributeToGoal extends Mock implements ContributeToGoal {}

GoalDetail _detail({int savedMinor = 0}) {
  final goal = buildGoal();
  return GoalDetail(
    progress: buildGoalWithProgress(goal: goal, savedMinor: savedMinor),
    projection: const GoalProjection(kind: GoalProjectionKind.noTargetDate),
    momentum: const GoalMomentum(streakWeeks: 0),
    history: const [],
  );
}

void main() {
  late MockWatchGoalDetail watchGoalDetail;
  late MockArchiveGoal archiveGoal;
  late MockDeleteGoal deleteGoal;
  late MockContributeToGoal contributeToGoal;

  setUp(() {
    watchGoalDetail = MockWatchGoalDetail();
    archiveGoal = MockArchiveGoal();
    deleteGoal = MockDeleteGoal();
    contributeToGoal = MockContributeToGoal();
  });

  GoalDetailCubit build() =>
      GoalDetailCubit(watchGoalDetail, archiveGoal, deleteGoal, contributeToGoal);

  blocTest<GoalDetailCubit, GoalDetailState>(
    'start emite loading y luego ready con el detalle',
    setUp: () => when(() => watchGoalDetail('g1'))
        .thenAnswer((_) => Stream.value(Right(_detail()))),
    build: build,
    act: (cubit) => cubit.start('g1'),
    expect: () => [
      isA<GoalDetailState>()
          .having((s) => s.status, 'status', GoalDetailStatus.loading),
      isA<GoalDetailState>()
          .having((s) => s.status, 'status', GoalDetailStatus.ready)
          .having((s) => s.detail, 'detail', isNotNull),
    ],
  );

  blocTest<GoalDetailCubit, GoalDetailState>(
    'expandMovements expande el peek de movimientos',
    setUp: () => when(() => watchGoalDetail('g1'))
        .thenAnswer((_) => Stream.value(Right(_detail()))),
    build: build,
    act: (cubit) async {
      await cubit.start('g1');
      cubit.expandMovements();
    },
    skip: 2,
    expect: () => [
      isA<GoalDetailState>()
          .having((s) => s.movementsExpanded, 'movementsExpanded', true),
    ],
  );

  blocTest<GoalDetailCubit, GoalDetailState>(
    'un error del stream lleva a failure',
    setUp: () => when(() => watchGoalDetail('g1')).thenAnswer(
      (_) => Stream.value(const Left(DatabaseFailure('boom'))),
    ),
    build: build,
    act: (cubit) => cubit.start('g1'),
    skip: 1,
    expect: () => [
      isA<GoalDetailState>()
          .having((s) => s.status, 'status', GoalDetailStatus.failure),
    ],
  );

  test('quickContribute delega en ContributeToGoal y expone el hito', () async {
    when(() => watchGoalDetail('g1'))
        .thenAnswer((_) => Stream.value(Right(_detail())));
    final movement = GoalContribution(
      id: 'm1',
      goalId: 'g1',
      amountMinor: 50000,
      direction: GoalMovementDirection.contribution,
      date: DateTime(2026, 7, 1),
      createdAt: DateTime(2026, 7, 1),
      updatedAt: DateTime(2026, 7, 1).millisecondsSinceEpoch,
    );
    when(
      () => contributeToGoal(
        goalId: any(named: 'goalId'),
        amountMinor: any(named: 'amountMinor'),
        date: any(named: 'date'),
        note: any(named: 'note'),
      ),
    ).thenAnswer((_) async => Right((movement, 50)));

    final cubit = build();
    await cubit.start('g1');
    final result = await cubit.quickContribute(50000);
    result.fold(
      (failure) => fail('expected a Right, got $failure'),
      (milestone) => expect(milestone, 50),
    );
    await cubit.close();
  });
}
