import 'package:billetudo/core/error/result.dart';
import 'package:billetudo/features/goals/domain/entities/goal_contribution.dart';
import 'package:billetudo/features/goals/domain/entities/goal_detail.dart';
import 'package:billetudo/features/goals/domain/entities/goal_momentum.dart';
import 'package:billetudo/features/goals/domain/entities/goal_projection.dart';
import 'package:billetudo/features/goals/domain/entities/goal_quick_amount.dart';
import 'package:billetudo/features/goals/domain/usecases/archive_goal.dart';
import 'package:billetudo/features/goals/domain/usecases/contribute_to_goal.dart';
import 'package:billetudo/features/goals/domain/usecases/create_goal_quick_amount.dart';
import 'package:billetudo/features/goals/domain/usecases/delete_goal.dart';
import 'package:billetudo/features/goals/domain/usecases/delete_goal_quick_amount.dart';
import 'package:billetudo/features/goals/domain/usecases/watch_goal_detail.dart';
import 'package:billetudo/features/goals/domain/usecases/watch_goal_quick_amounts.dart';
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

class MockWatchGoalQuickAmounts extends Mock implements WatchGoalQuickAmounts {}

class MockCreateGoalQuickAmount extends Mock implements CreateGoalQuickAmount {}

class MockDeleteGoalQuickAmount extends Mock implements DeleteGoalQuickAmount {}

GoalQuickAmount _quickAmount({
  String id = 'qa1',
  String goalId = 'g1',
  int amountMinor = 20000,
}) =>
    GoalQuickAmount(
      id: id,
      goalId: goalId,
      amountMinor: amountMinor,
      createdAt: DateTime(2026, 7, 1),
      updatedAt: DateTime(2026, 7, 1).millisecondsSinceEpoch,
    );

GoalDetail _detail({int savedMinor = 0, List<GoalContribution> history = const []}) {
  final goal = buildGoal();
  return GoalDetail(
    progress: buildGoalWithProgress(goal: goal, savedMinor: savedMinor),
    projection: const GoalProjection(kind: GoalProjectionKind.noTargetDate),
    momentum: const GoalMomentum(streakWeeks: 0),
    history: history,
  );
}

List<GoalContribution> _history(int count) => List.generate(
      count,
      (index) => GoalContribution(
        id: 'm$index',
        goalId: 'g1',
        amountMinor: 10000,
        direction: GoalMovementDirection.contribution,
        date: DateTime(2026, 7, 1).subtract(Duration(days: index)),
        createdAt: DateTime(2026, 7, 1),
        updatedAt: DateTime(2026, 7, 1).millisecondsSinceEpoch,
      ),
    );

void main() {
  late MockWatchGoalDetail watchGoalDetail;
  late MockArchiveGoal archiveGoal;
  late MockDeleteGoal deleteGoal;
  late MockContributeToGoal contributeToGoal;
  late MockWatchGoalQuickAmounts watchGoalQuickAmounts;
  late MockCreateGoalQuickAmount createGoalQuickAmount;
  late MockDeleteGoalQuickAmount deleteGoalQuickAmount;

  setUp(() {
    watchGoalDetail = MockWatchGoalDetail();
    archiveGoal = MockArchiveGoal();
    deleteGoal = MockDeleteGoal();
    contributeToGoal = MockContributeToGoal();
    watchGoalQuickAmounts = MockWatchGoalQuickAmounts();
    createGoalQuickAmount = MockCreateGoalQuickAmount();
    deleteGoalQuickAmount = MockDeleteGoalQuickAmount();
    when(() => watchGoalQuickAmounts(any()))
        .thenAnswer((_) => Stream.value(const Right(<GoalQuickAmount>[])));
  });

  GoalDetailCubit build() => GoalDetailCubit(
        watchGoalDetail,
        archiveGoal,
        deleteGoal,
        contributeToGoal,
        watchGoalQuickAmounts,
        createGoalQuickAmount,
        deleteGoalQuickAmount,
      );

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
    'con 8 movimientos o menos no hay más para revelar',
    setUp: () => when(() => watchGoalDetail('g1')).thenAnswer(
      (_) => Stream.value(Right(_detail(history: _history(8)))),
    ),
    build: build,
    act: (cubit) => cubit.start('g1'),
    skip: 1,
    expect: () => [
      isA<GoalDetailState>()
          .having((s) => s.hasMoreMovements, 'hasMoreMovements', false)
          .having((s) => s.visibleMovements.length, 'visibleMovements', 8),
    ],
  );

  blocTest<GoalDetailCubit, GoalDetailState>(
    'loadMoreMovements revela 8 más a la vez, nunca todos de un tiro',
    setUp: () => when(() => watchGoalDetail('g1')).thenAnswer(
      (_) => Stream.value(Right(_detail(history: _history(20)))),
    ),
    build: build,
    act: (cubit) async {
      await cubit.start('g1');
      await Future<void>.delayed(Duration.zero);
      cubit.loadMoreMovements();
    },
    skip: 1,
    expect: () => [
      isA<GoalDetailState>()
          .having((s) => s.hasMoreMovements, 'hasMoreMovements', true)
          .having((s) => s.visibleMovements.length, 'visibleMovements', 8),
      isA<GoalDetailState>()
          .having((s) => s.hasMoreMovements, 'hasMoreMovements', true)
          .having((s) => s.visibleMovements.length, 'visibleMovements', 16),
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

  blocTest<GoalDetailCubit, GoalDetailState>(
    'expone los chips personalizados de aporte rápido del stream',
    setUp: () {
      when(() => watchGoalDetail('g1'))
          .thenAnswer((_) => Stream.value(Right(_detail())));
      when(() => watchGoalQuickAmounts('g1')).thenAnswer(
        (_) => Stream.value(Right([_quickAmount()])),
      );
    },
    build: build,
    act: (cubit) => cubit.start('g1'),
    skip: 2,
    expect: () => [
      isA<GoalDetailState>()
          .having((s) => s.quickAmounts, 'quickAmounts', [_quickAmount()]),
    ],
  );

  test('createQuickAmount delega en CreateGoalQuickAmount', () async {
    when(() => watchGoalDetail('g1'))
        .thenAnswer((_) => Stream.value(Right(_detail())));
    when(
      () => createGoalQuickAmount(
        goalId: any(named: 'goalId'),
        amountMinor: any(named: 'amountMinor'),
      ),
    ).thenAnswer((_) async => Right(_quickAmount()));

    final cubit = build();
    await cubit.start('g1');
    final result = await cubit.createQuickAmount(20000);

    verify(
      () => createGoalQuickAmount(goalId: 'g1', amountMinor: 20000),
    ).called(1);
    result.fold(
      (failure) => fail('expected a Right, got $failure'),
      (quickAmount) => expect(quickAmount, _quickAmount()),
    );
    await cubit.close();
  });

  test('deleteQuickAmount delega en DeleteGoalQuickAmount', () async {
    when(() => watchGoalDetail('g1'))
        .thenAnswer((_) => Stream.value(Right(_detail())));
    when(() => deleteGoalQuickAmount('qa1'))
        .thenAnswer((_) async => const Right(unit));

    final cubit = build();
    await cubit.start('g1');
    final result = await cubit.deleteQuickAmount('qa1');

    verify(() => deleteGoalQuickAmount('qa1')).called(1);
    expect(result.isRight(), isTrue);
    await cubit.close();
  });
}
