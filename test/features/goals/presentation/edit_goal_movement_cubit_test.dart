import 'package:billetudo/core/error/result.dart';
import 'package:billetudo/features/goals/domain/entities/goal_contribution.dart';
import 'package:billetudo/features/goals/domain/usecases/update_goal_movement.dart';
import 'package:billetudo/features/goals/presentation/cubit/edit_goal_movement_cubit.dart';
import 'package:billetudo/features/goals/presentation/cubit/edit_goal_movement_state.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'goals_presentation_fixtures.dart';

class MockUpdateGoalMovement extends Mock implements UpdateGoalMovement {}

void main() {
  late MockUpdateGoalMovement updateGoalMovement;

  setUp(() {
    updateGoalMovement = MockUpdateGoalMovement();
  });

  EditGoalMovementCubit build() => EditGoalMovementCubit(updateGoalMovement);

  group('start', () {
    blocTest<EditGoalMovementCubit, EditGoalMovementState>(
      'precarga monto/fecha/nota del movimiento y el nombre/moneda de la meta',
      build: build,
      act: (cubit) => cubit.start(
        buildGoalContribution(
          id: 'm1',
          goalId: 'g1',
          amountMinor: 7500,
          date: DateTime(2026, 7, 12),
          note: 'regalo',
        ),
        goalName: 'Viaje a Cartagena',
        currency: 'COP',
      ),
      expect: () => [
        isA<EditGoalMovementState>()
            .having((s) => s.contributionId, 'contributionId', 'm1')
            .having((s) => s.goalId, 'goalId', 'g1')
            .having((s) => s.goalName, 'goalName', 'Viaje a Cartagena')
            .having((s) => s.currency, 'currency', 'COP')
            .having((s) => s.amountMinor, 'amountMinor', 7500)
            .having((s) => s.date, 'date', DateTime(2026, 7, 12))
            .having((s) => s.note, 'note', 'regalo'),
      ],
    );

    blocTest<EditGoalMovementCubit, EditGoalMovementState>(
      'una nota nula precarga un campo vacío',
      build: build,
      act: (cubit) => cubit.start(
        buildGoalContribution(note: null),
        goalName: 'Viaje',
        currency: 'COP',
      ),
      expect: () => [
        isA<EditGoalMovementState>().having((s) => s.note, 'note', ''),
      ],
    );
  });

  group('field changes', () {
    blocTest<EditGoalMovementCubit, EditGoalMovementState>(
      'amountChanged/dateChanged/noteChanged actualizan el estado',
      build: build,
      seed: () => EditGoalMovementState(
        contributionId: 'm1',
        goalId: 'g1',
        goalName: 'Viaje',
        direction: GoalMovementDirection.contribution,
        currency: 'COP',
        date: DateTime(2026, 7, 1),
      ),
      act: (cubit) {
        cubit.amountChanged(12000);
        cubit.dateChanged(DateTime(2026, 7, 20));
        cubit.noteChanged('nueva nota');
      },
      expect: () => [
        isA<EditGoalMovementState>()
            .having((s) => s.amountMinor, 'amountMinor', 12000),
        isA<EditGoalMovementState>()
            .having((s) => s.date, 'date', DateTime(2026, 7, 20)),
        isA<EditGoalMovementState>()
            .having((s) => s.note, 'note', 'nueva nota'),
      ],
    );
  });

  group('submit', () {
    blocTest<EditGoalMovementCubit, EditGoalMovementState>(
      'una edición exitosa pasa por saving y termina en saved',
      setUp: () => when(
        () => updateGoalMovement(
          contributionId: any(named: 'contributionId'),
          amountMinor: any(named: 'amountMinor'),
          date: any(named: 'date'),
          note: any(named: 'note'),
        ),
      ).thenAnswer((_) async => const Right(unit)),
      build: build,
      seed: () => EditGoalMovementState(
        contributionId: 'm1',
        goalId: 'g1',
        goalName: 'Viaje',
        direction: GoalMovementDirection.contribution,
        currency: 'COP',
        amountMinor: 9000,
        date: DateTime(2026, 7, 15),
        note: '  regalo  ',
      ),
      act: (cubit) => cubit.submit(),
      expect: () => [
        isA<EditGoalMovementState>()
            .having((s) => s.status, 'status', EditGoalMovementStatus.saving),
        isA<EditGoalMovementState>()
            .having((s) => s.status, 'status', EditGoalMovementStatus.saved),
      ],
      verify: (_) {
        final captured = verify(
          () => updateGoalMovement(
            contributionId: captureAny(named: 'contributionId'),
            amountMinor: captureAny(named: 'amountMinor'),
            date: captureAny(named: 'date'),
            note: captureAny(named: 'note'),
          ),
        ).captured;
        expect(captured[0], 'm1');
        expect(captured[1], 9000);
        expect(captured[2], DateTime(2026, 7, 15));
        expect(captured[3], 'regalo');
      },
    );

    blocTest<EditGoalMovementCubit, EditGoalMovementState>(
      'una edición rechazada (p.ej. dejaría el saved negativo) termina en '
      'failure sin limpiar el monto ingresado',
      setUp: () => when(
        () => updateGoalMovement(
          contributionId: any(named: 'contributionId'),
          amountMinor: any(named: 'amountMinor'),
          date: any(named: 'date'),
          note: any(named: 'note'),
        ),
      ).thenAnswer(
        (_) async => const Left(
          ValidationFailure(
            'a withdrawal cannot leave the goal\'s saved amount negative',
          ),
        ),
      ),
      build: build,
      seed: () => EditGoalMovementState(
        contributionId: 'm1',
        goalId: 'g1',
        goalName: 'Viaje',
        direction: GoalMovementDirection.withdrawal,
        currency: 'COP',
        amountMinor: 999999,
        date: DateTime(2026, 7, 15),
      ),
      act: (cubit) => cubit.submit(),
      expect: () => [
        isA<EditGoalMovementState>()
            .having((s) => s.status, 'status', EditGoalMovementStatus.saving),
        isA<EditGoalMovementState>()
            .having((s) => s.status, 'status', EditGoalMovementStatus.failure)
            .having((s) => s.failure, 'failure', isA<ValidationFailure>())
            .having((s) => s.amountMinor, 'amountMinor', 999999),
      ],
    );

    blocTest<EditGoalMovementCubit, EditGoalMovementState>(
      'no hace nada si el monto es 0 (canSubmit en false)',
      build: build,
      seed: () => EditGoalMovementState(
        contributionId: 'm1',
        goalId: 'g1',
        goalName: 'Viaje',
        direction: GoalMovementDirection.contribution,
        currency: 'COP',
        date: DateTime(2026, 7, 15),
      ),
      act: (cubit) => cubit.submit(),
      expect: () => <EditGoalMovementState>[],
      verify: (_) => verifyNever(
        () => updateGoalMovement(
          contributionId: any(named: 'contributionId'),
          amountMinor: any(named: 'amountMinor'),
          date: any(named: 'date'),
          note: any(named: 'note'),
        ),
      ),
    );
  });
}
