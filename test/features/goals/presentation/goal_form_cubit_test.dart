import 'package:billetudo/core/error/result.dart';
import 'package:billetudo/features/accounts/domain/entities/account_with_balance.dart';
import 'package:billetudo/features/accounts/domain/usecases/watch_accounts.dart';
import 'package:billetudo/features/goals/domain/entities/goal.dart';
import 'package:billetudo/features/goals/domain/entities/goal_detail.dart';
import 'package:billetudo/features/goals/domain/entities/goal_draft.dart';
import 'package:billetudo/features/goals/domain/entities/goal_momentum.dart';
import 'package:billetudo/features/goals/domain/entities/goal_projection.dart';
import 'package:billetudo/features/goals/domain/entities/goal_with_progress.dart';
import 'package:billetudo/features/goals/domain/usecases/create_goal.dart';
import 'package:billetudo/features/goals/domain/usecases/delete_goal.dart';
import 'package:billetudo/features/goals/domain/usecases/update_goal.dart';
import 'package:billetudo/features/goals/domain/usecases/watch_goal_detail.dart';
import 'package:billetudo/features/goals/presentation/cubit/goal_form_cubit.dart';
import 'package:billetudo/features/goals/presentation/cubit/goal_form_state.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../accounts/account_fixtures.dart';

class MockCreateGoal extends Mock implements CreateGoal {}

class MockUpdateGoal extends Mock implements UpdateGoal {}

class MockDeleteGoal extends Mock implements DeleteGoal {}

class MockWatchGoalDetail extends Mock implements WatchGoalDetail {}

class MockWatchAccounts extends Mock implements WatchAccounts {}

void main() {
  late MockCreateGoal createGoal;
  late MockUpdateGoal updateGoal;
  late MockDeleteGoal deleteGoal;
  late MockWatchGoalDetail watchGoalDetail;
  late MockWatchAccounts watchAccounts;

  setUp(() {
    createGoal = MockCreateGoal();
    updateGoal = MockUpdateGoal();
    deleteGoal = MockDeleteGoal();
    watchGoalDetail = MockWatchGoalDetail();
    watchAccounts = MockWatchAccounts();
    when(watchAccounts.call)
        .thenAnswer((_) => Stream.value(const Right(<AccountWithBalance>[])));
    registerFallbackValue(
      const GoalDraft(name: 'x', targetMinor: 1, currency: 'COP'),
    );
  });

  GoalFormCubit build() => GoalFormCubit(
        createGoal,
        updateGoal,
        deleteGoal,
        watchGoalDetail,
        watchAccounts,
      );

  Goal buildGoal() => Goal(
        id: 'g1',
        name: 'Viaje',
        targetMinor: 500000,
        currency: 'COP',
        lastMilestonePct: 0,
        createdAt: DateTime(2026, 1, 1),
        updatedAt: DateTime(2026, 1, 1).millisecondsSinceEpoch,
      );

  blocTest<GoalFormCubit, GoalFormState>(
    'load(null) prepara un formulario vacío listo para crear',
    build: build,
    act: (cubit) => cubit.load(null),
    expect: () => [
      isA<GoalFormState>()
          .having((s) => s.status, 'status', GoalFormStatus.ready)
          .having((s) => s.isEditing, 'isEditing', false),
    ],
  );

  blocTest<GoalFormCubit, GoalFormState>(
    'submit exitoso en creación emite saved',
    setUp: () => when(() => createGoal(any()))
        .thenAnswer((_) async => Right(buildGoal())),
    build: build,
    act: (cubit) async {
      await cubit.load(null);
      cubit.nameChanged('Viaje');
      cubit.targetMinorChanged(500000);
      await cubit.submit();
    },
    skip: 3,
    expect: () => [
      isA<GoalFormState>()
          .having((s) => s.status, 'status', GoalFormStatus.saving),
      isA<GoalFormState>()
          .having((s) => s.status, 'status', GoalFormStatus.saved),
    ],
  );

  blocTest<GoalFormCubit, GoalFormState>(
    'una falla de validación surge como failedField',
    setUp: () => when(() => createGoal(any())).thenAnswer(
      (_) async => const Left(
        ValidationFailure('a name is required', field: GoalDraft.fieldName),
      ),
    ),
    build: build,
    act: (cubit) async {
      await cubit.load(null);
      await cubit.submit();
    },
    skip: 1,
    expect: () => [
      isA<GoalFormState>()
          .having((s) => s.status, 'status', GoalFormStatus.saving),
      isA<GoalFormState>()
          .having((s) => s.status, 'status', GoalFormStatus.ready)
          .having((s) => s.failedField, 'failedField', GoalDraft.fieldName),
    ],
  );

  blocTest<GoalFormCubit, GoalFormState>(
    'delete exitoso emite deleted, tras cargar una meta existente',
    setUp: () {
      final goal = buildGoal();
      when(() => watchGoalDetail(any())).thenAnswer(
        (_) => Stream.value(
          Right(
            GoalDetail(
              progress: GoalWithProgress(
                goal: goal,
                savedMinor: 0,
                displayedPercent: 0,
                remainingMinor: goal.targetMinor,
              ),
              projection: const GoalProjection(
                kind: GoalProjectionKind.noTargetDate,
              ),
              momentum: const GoalMomentum(streakWeeks: 0),
              history: const [],
            ),
          ),
        ),
      );
      when(() => deleteGoal(any())).thenAnswer((_) async => const Right(unit));
    },
    build: build,
    act: (cubit) async {
      await cubit.load('g1');
      await cubit.delete();
    },
    skip: 1,
    expect: () => [
      isA<GoalFormState>()
          .having((s) => s.status, 'status', GoalFormStatus.saving),
      isA<GoalFormState>()
          .having((s) => s.status, 'status', GoalFormStatus.deleted),
    ],
  );

  blocTest<GoalFormCubit, GoalFormState>(
    'refreshAccounts recarga la lista de cuentas tras crear una desde el '
    'gate ("Cuenta vinculada", 15-gate-cuenta.md)',
    setUp: () {
      final account = buildAccountWithBalance(
        account: buildAccount(id: 'a1', name: 'Ahorros'),
        balanceMinor: 0,
      );
      var call = 0;
      when(watchAccounts.call).thenAnswer((_) {
        call += 1;
        // First call (inside `load`) mirrors the "sin cuentas" starting
        // point; the second (inside `refreshAccounts`) mirrors the account
        // just created from the gate — the two must differ, or `Cubit`'s
        // equality check on `GoalFormState` (Equatable) would swallow the
        // second emit as a no-op.
        return Stream.value(
          Right(call == 1 ? const <AccountWithBalance>[] : [account]),
        );
      });
    },
    build: build,
    act: (cubit) async {
      await cubit.load(null);
      await cubit.refreshAccounts();
    },
    skip: 1,
    expect: () => [
      isA<GoalFormState>()
          .having((s) => s.accounts, 'accounts', hasLength(1)),
    ],
  );
}
