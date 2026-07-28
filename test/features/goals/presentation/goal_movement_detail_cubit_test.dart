import 'package:billetudo/core/error/result.dart';
import 'package:billetudo/features/goals/domain/entities/goal_movement_accounts.dart';
import 'package:billetudo/features/goals/domain/usecases/get_goal_movement_accounts.dart';
import 'package:billetudo/features/goals/domain/usecases/remove_goal_movement.dart';
import 'package:billetudo/features/goals/presentation/cubit/goal_movement_detail_cubit.dart';
import 'package:billetudo/features/goals/presentation/cubit/goal_movement_detail_state.dart';
import 'package:billetudo/features/transactions/domain/usecases/delete_transaction.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'goals_presentation_fixtures.dart';

class MockGetGoalMovementAccounts extends Mock
    implements GetGoalMovementAccounts {}

class MockRemoveGoalMovement extends Mock implements RemoveGoalMovement {}

class MockDeleteTransaction extends Mock implements DeleteTransaction {}

void main() {
  late MockGetGoalMovementAccounts getMovementAccounts;
  late MockRemoveGoalMovement removeGoalMovement;
  late MockDeleteTransaction deleteTransaction;

  setUp(() {
    getMovementAccounts = MockGetGoalMovementAccounts();
    removeGoalMovement = MockRemoveGoalMovement();
    deleteTransaction = MockDeleteTransaction();
  });

  GoalMovementDetailCubit build() => GoalMovementDetailCubit(
        getMovementAccounts,
        removeGoalMovement,
        deleteTransaction,
      );

  group('start', () {
    blocTest<GoalMovementDetailCubit, GoalMovementDetailState>(
      'un movimiento de seguimiento puro va directo a ready sin cuentas',
      build: build,
      act: (cubit) => cubit.start(buildGoalContribution(transactionId: null)),
      expect: () => [
        isA<GoalMovementDetailState>()
            .having((s) => s.status, 'status', GoalMovementDetailStatus.ready)
            .having((s) => s.accounts, 'accounts', isNull),
      ],
      verify: (_) => verifyNever(() => getMovementAccounts.call(any())),
    );

    blocTest<GoalMovementDetailCubit, GoalMovementDetailState>(
      'un movimiento con transferencia resuelve las cuentas',
      setUp: () => when(() => getMovementAccounts.call(any())).thenAnswer(
        (_) async => const Right(
          GoalMovementAccounts(
            originName: 'Nequi',
            destinationName: 'Ahorros Bancolombia',
          ),
        ),
      ),
      build: build,
      act: (cubit) =>
          cubit.start(buildGoalContribution(transactionId: 'tx-1')),
      skip: 1,
      expect: () => [
        isA<GoalMovementDetailState>()
            .having((s) => s.status, 'status', GoalMovementDetailStatus.ready)
            .having(
              (s) => s.accounts?.originName,
              'accounts.originName',
              'Nequi',
            ),
      ],
    );

    blocTest<GoalMovementDetailCubit, GoalMovementDetailState>(
      'una falla al resolver cuentas lleva a failure',
      setUp: () => when(() => getMovementAccounts.call(any())).thenAnswer(
        (_) async => const Left(DatabaseFailure('boom')),
      ),
      build: build,
      act: (cubit) =>
          cubit.start(buildGoalContribution(transactionId: 'tx-1')),
      skip: 1,
      expect: () => [
        isA<GoalMovementDetailState>().having(
          (s) => s.status,
          'status',
          GoalMovementDetailStatus.failure,
        ),
      ],
    );
  });

  group('delete', () {
    test('un movimiento manual se elimina vía RemoveGoalMovement', () async {
      when(() => removeGoalMovement.call(any()))
          .thenAnswer((_) async => const Right(unit));

      final movement = buildGoalContribution(id: 'm1', transactionId: null);
      final result = await build().delete(movement);

      expect(result.isRight(), isTrue);
      verify(() => removeGoalMovement.call('m1')).called(1);
      verifyNever(() => deleteTransaction.call(any()));
    });

    test(
      'un movimiento con transferencia se elimina vía DeleteTransaction',
      () async {
        when(() => deleteTransaction.call(any()))
            .thenAnswer((_) async => const Right(unit));

        final movement =
            buildGoalContribution(id: 'm1', transactionId: 'tx-1');
        final result = await build().delete(movement);

        expect(result.isRight(), isTrue);
        verify(() => deleteTransaction.call('tx-1')).called(1);
        verifyNever(() => removeGoalMovement.call(any()));
      },
    );
  });
}
