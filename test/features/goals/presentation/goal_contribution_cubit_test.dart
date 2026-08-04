import 'package:billetudo/core/error/result.dart';
import 'package:billetudo/features/accounts/domain/entities/account_with_balance.dart';
import 'package:billetudo/features/accounts/domain/usecases/watch_accounts.dart';
import 'package:billetudo/features/goals/domain/entities/goal_contribution.dart';
import 'package:billetudo/features/goals/domain/services/goal_category_seed.dart';
import 'package:billetudo/features/goals/domain/usecases/contribute_to_goal.dart';
import 'package:billetudo/features/goals/domain/usecases/withdraw_from_goal.dart';
import 'package:billetudo/features/goals/presentation/cubit/goal_contribution_cubit.dart';
import 'package:billetudo/features/goals/presentation/cubit/goal_contribution_state.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../accounts/account_fixtures.dart';

class MockContributeToGoal extends Mock implements ContributeToGoal {}

class MockWithdrawFromGoal extends Mock implements WithdrawFromGoal {}

class MockWatchAccounts extends Mock implements WatchAccounts {}

GoalContribution _movement({
  GoalMovementDirection direction = GoalMovementDirection.contribution,
  int amountMinor = 50000,
}) =>
    GoalContribution(
      id: 'm1',
      goalId: 'g1',
      amountMinor: amountMinor,
      direction: direction,
      date: DateTime(2026, 7, 1),
      createdAt: DateTime(2026, 7, 1),
      updatedAt: DateTime(2026, 7, 1).millisecondsSinceEpoch,
    );

void main() {
  late MockContributeToGoal contribute;
  late MockWithdrawFromGoal withdraw;
  late MockWatchAccounts watchAccounts;

  final accounts = [
    buildAccountWithBalance(
      account: buildAccount(id: 'a1', name: 'Nequi'),
      balanceMinor: 1240000,
    ),
  ];

  setUp(() {
    contribute = MockContributeToGoal();
    withdraw = MockWithdrawFromGoal();
    watchAccounts = MockWatchAccounts();
    when(() => watchAccounts()).thenAnswer(
      (_) => Stream.value(Right<Failure, List<AccountWithBalance>>(accounts)),
    );
  });

  GoalContributionCubit build() =>
      GoalContributionCubit(contribute, withdraw, watchAccounts);

  blocTest<GoalContributionCubit, GoalContributionState>(
    'un aporte exitoso queda saved y expone el hito cruzado',
    setUp: () => when(
      () => contribute(
        goalId: any(named: 'goalId'),
        amountMinor: any(named: 'amountMinor'),
        date: any(named: 'date'),
        note: any(named: 'note'),
        moveMoney: any(named: 'moveMoney'),
        sourceAccountId: any(named: 'sourceAccountId'),
        categoryId: any(named: 'categoryId'),
        countsInBudget: any(named: 'countsInBudget'),
      ),
    ).thenAnswer((_) async => Right((_movement(), 50))),
    build: build,
    act: (cubit) async {
      await cubit.start(
        goalId: 'g1',
        goalName: 'Viaje a Cartagena',
        direction: GoalMovementDirection.contribution,
        currency: 'COP',
      );
      cubit.amountChanged(50000);
      return cubit.submit();
    },
    skip: 4,
    expect: () => [
      isA<GoalContributionState>()
          .having((s) => s.status, 'status', GoalContributionStatus.saved)
          .having((s) => s.milestoneCrossed, 'milestoneCrossed', 50),
    ],
  );

  blocTest<GoalContributionCubit, GoalContributionState>(
    'un retiro que excede el máximo no habilita el submit (canSubmit)',
    build: build,
    act: (cubit) async {
      await cubit.start(
        goalId: 'g1',
        goalName: 'Viaje a Cartagena',
        direction: GoalMovementDirection.withdrawal,
        currency: 'COP',
        maxWithdrawableMinor: 10000,
      );
      cubit.amountChanged(20000);
    },
    verify: (cubit) => expect(cubit.state.canSubmit, isFalse),
  );

  blocTest<GoalContributionCubit, GoalContributionState>(
    'useMax limita el monto al máximo retirable',
    build: build,
    act: (cubit) async {
      await cubit.start(
        goalId: 'g1',
        goalName: 'Viaje a Cartagena',
        direction: GoalMovementDirection.withdrawal,
        currency: 'COP',
        maxWithdrawableMinor: 30000,
      );
      cubit.useMax();
    },
    verify: (cubit) => expect(cubit.state.amountMinor, 30000),
  );

  blocTest<GoalContributionCubit, GoalContributionState>(
    'una falla del caso de uso lleva a failure',
    setUp: () => when(
      () => contribute(
        goalId: any(named: 'goalId'),
        amountMinor: any(named: 'amountMinor'),
        date: any(named: 'date'),
        note: any(named: 'note'),
        moveMoney: any(named: 'moveMoney'),
        sourceAccountId: any(named: 'sourceAccountId'),
        categoryId: any(named: 'categoryId'),
        countsInBudget: any(named: 'countsInBudget'),
      ),
    ).thenAnswer((_) async => const Left(ValidationFailure('boom'))),
    build: build,
    act: (cubit) async {
      await cubit.start(
        goalId: 'g1',
        goalName: 'Viaje a Cartagena',
        direction: GoalMovementDirection.contribution,
        currency: 'COP',
      );
      cubit.amountChanged(50000);
      return cubit.submit();
    },
    skip: 4,
    expect: () => [
      isA<GoalContributionState>()
          .having((s) => s.status, 'status', GoalContributionStatus.failure)
          .having((s) => s.failure, 'failure', isNotNull),
    ],
  );

  group('mover dinero (toggle ON)', () {
    blocTest<GoalContributionCubit, GoalContributionState>(
      'start carga las cuentas activas',
      build: build,
      act: (cubit) => cubit.start(
        goalId: 'g1',
        goalName: 'Viaje a Cartagena',
        direction: GoalMovementDirection.contribution,
        currency: 'COP',
      ),
      verify: (cubit) => expect(cubit.state.accounts, accounts),
    );

    blocTest<GoalContributionCubit, GoalContributionState>(
      'sin cuenta vinculada, el toggle no se activa',
      build: build,
      act: (cubit) async {
        await cubit.start(
          goalId: 'g1',
          goalName: 'Viaje a Cartagena',
          direction: GoalMovementDirection.contribution,
          currency: 'COP',
          hasLinkedAccount: false,
        );
        cubit.toggleMoveMoney(true);
      },
      verify: (cubit) => expect(cubit.state.moveMoney, isFalse),
    );

    blocTest<GoalContributionCubit, GoalContributionState>(
      'activar el toggle sin cuenta elegida no habilita el submit',
      build: build,
      act: (cubit) async {
        await cubit.start(
          goalId: 'g1',
          goalName: 'Viaje a Cartagena',
          direction: GoalMovementDirection.contribution,
          currency: 'COP',
        );
        cubit.amountChanged(50000);
        cubit.toggleMoveMoney(true);
      },
      verify: (cubit) => expect(cubit.state.canSubmit, isFalse),
    );

    blocTest<GoalContributionCubit, GoalContributionState>(
      'elegir cuenta habilita el submit',
      build: build,
      act: (cubit) async {
        await cubit.start(
          goalId: 'g1',
          goalName: 'Viaje a Cartagena',
          direction: GoalMovementDirection.contribution,
          currency: 'COP',
        );
        cubit.amountChanged(50000);
        cubit.toggleMoveMoney(true);
        cubit.selectAccount('a1');
      },
      verify: (cubit) => expect(cubit.state.canSubmit, isTrue),
    );

    blocTest<GoalContributionCubit, GoalContributionState>(
      'apagar el toggle limpia cuenta/presupuesto/categoría',
      build: build,
      act: (cubit) async {
        await cubit.start(
          goalId: 'g1',
          goalName: 'Viaje a Cartagena',
          direction: GoalMovementDirection.contribution,
          currency: 'COP',
        );
        cubit.toggleMoveMoney(true);
        cubit.selectAccount('a1');
        cubit.toggleCountsInBudget(true);
        cubit.toggleMoveMoney(false);
      },
      verify: (cubit) {
        expect(cubit.state.selectedAccountId, isNull);
        expect(cubit.state.countsInBudget, isFalse);
        expect(cubit.state.categoryId, isNull);
      },
    );

    blocTest<GoalContributionCubit, GoalContributionState>(
      'incluir en presupuesto preselecciona la categoría "Ahorros"',
      build: build,
      act: (cubit) async {
        await cubit.start(
          goalId: 'g1',
          goalName: 'Viaje a Cartagena',
          direction: GoalMovementDirection.contribution,
          currency: 'COP',
        );
        cubit.toggleMoveMoney(true);
        cubit.toggleCountsInBudget(true);
      },
      verify: (cubit) => expect(
        cubit.state.categoryId,
        GoalCategorySeed.savingsCategoryId,
      ),
    );

    blocTest<GoalContributionCubit, GoalContributionState>(
      'submit con mover dinero pasa la cuenta y categoría al caso de uso',
      setUp: () => when(
        () => contribute(
          goalId: any(named: 'goalId'),
          amountMinor: any(named: 'amountMinor'),
          date: any(named: 'date'),
          note: any(named: 'note'),
          moveMoney: any(named: 'moveMoney'),
          sourceAccountId: any(named: 'sourceAccountId'),
          categoryId: any(named: 'categoryId'),
          countsInBudget: any(named: 'countsInBudget'),
        ),
      ).thenAnswer((_) async => Right((_movement(), null))),
      build: build,
      act: (cubit) async {
        await cubit.start(
          goalId: 'g1',
          goalName: 'Viaje a Cartagena',
          direction: GoalMovementDirection.contribution,
          currency: 'COP',
        );
        cubit.amountChanged(50000);
        cubit.toggleMoveMoney(true);
        cubit.selectAccount('a1');
        cubit.toggleCountsInBudget(true);
        await cubit.submit();
      },
      verify: (_) {
        verify(
          () => contribute(
            goalId: 'g1',
            amountMinor: 50000,
            date: any(named: 'date'),
            note: null,
            moveMoney: true,
            sourceAccountId: 'a1',
            categoryId: GoalCategorySeed.savingsCategoryId,
            countsInBudget: true,
          ),
        ).called(1);
      },
    );
  });
}
