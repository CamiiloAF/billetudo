import 'package:billetudo/core/error/result.dart';
import 'package:billetudo/features/auth/domain/entities/delete_account_scope.dart';
import 'package:billetudo/features/auth/domain/entities/local_data_choice.dart';
import 'package:billetudo/features/auth/domain/usecases/delete_account.dart';
import 'package:billetudo/features/auth/domain/usecases/get_delete_account_scope.dart';
import 'package:billetudo/features/auth/domain/usecases/wipe_local_data.dart';
import 'package:billetudo/features/auth/presentation/cubit/delete_account_cubit.dart';
import 'package:billetudo/features/auth/presentation/cubit/delete_account_state.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockDeleteAccount extends Mock implements DeleteAccount {}

class MockWipeLocalData extends Mock implements WipeLocalData {}

class MockGetDeleteAccountScope extends Mock
    implements GetDeleteAccountScope {}

void main() {
  late MockDeleteAccount deleteAccount;
  late MockWipeLocalData wipeLocalData;
  late MockGetDeleteAccountScope getDeleteAccountScope;

  setUp(() {
    deleteAccount = MockDeleteAccount();
    wipeLocalData = MockWipeLocalData();
    getDeleteAccountScope = MockGetDeleteAccountScope();
    when(() => getDeleteAccountScope())
        .thenAnswer((_) async => DeleteAccountScope.cloudAndLocal);
  });

  DeleteAccountCubit build() => DeleteAccountCubit(
        deleteAccount,
        wipeLocalData,
        getDeleteAccountScope,
      );

  blocTest<DeleteAccountCubit, DeleteAccountState>(
    'HU-07 paso 1: confirmDelete exitoso avanza a localDataChoice',
    build: build,
    setUp: () =>
        when(() => deleteAccount()).thenAnswer((_) async => const Right(unit)),
    act: (cubit) => cubit.confirmDelete(),
    expect: () => [
      const DeleteAccountState(status: DeleteAccountStatus.loading),
      const DeleteAccountState(step: DeleteAccountStep.localDataChoice),
    ],
  );

  blocTest<DeleteAccountCubit, DeleteAccountState>(
    'HU-07 paso 1: sin sesión activa, confirmDelete avanza a localDataChoice '
    'sin pasar por error (regresión: AuthRepositoryImpl.deleteAccount ahora '
    'devuelve Right(unit) de inmediato cuando no hay sesión, sin invocar la '
    'Edge Function)',
    build: build,
    setUp: () =>
        when(() => deleteAccount()).thenAnswer((_) async => const Right(unit)),
    act: (cubit) => cubit.confirmDelete(),
    expect: () => [
      const DeleteAccountState(status: DeleteAccountStatus.loading),
      const DeleteAccountState(step: DeleteAccountStep.localDataChoice),
    ],
    verify: (_) {
      verify(() => deleteAccount()).called(1);
    },
  );

  blocTest<DeleteAccountCubit, DeleteAccountState>(
    'HU-07 paso 1: un fallo se queda en confirm con estado error',
    build: build,
    setUp: () => when(() => deleteAccount())
        .thenAnswer((_) async => const Left(NetworkFailure('offline'))),
    act: (cubit) => cubit.confirmDelete(),
    expect: () => [
      const DeleteAccountState(status: DeleteAccountStatus.loading),
      isA<DeleteAccountState>()
          .having((s) => s.step, 'step', DeleteAccountStep.confirm)
          .having((s) => s.status, 'status', DeleteAccountStatus.error),
    ],
  );

  blocTest<DeleteAccountCubit, DeleteAccountState>(
    'HU-07 paso 2: elegir "conservar" avanza directo a done sin borrar nada',
    build: build,
    seed: () =>
        const DeleteAccountState(step: DeleteAccountStep.localDataChoice),
    act: (cubit) {
      cubit.selectLocalDataChoice(LocalDataChoice.keep);
      return cubit.confirmLocalDataChoice();
    },
    verify: (_) => verifyNever(() => wipeLocalData()),
    expect: () => [
      const DeleteAccountState(
        step: DeleteAccountStep.localDataChoice,
        choice: LocalDataChoice.keep,
      ),
      const DeleteAccountState(
        step: DeleteAccountStep.done,
        choice: LocalDataChoice.keep,
      ),
    ],
  );

  blocTest<DeleteAccountCubit, DeleteAccountState>(
    'HU-07 paso 2: elegir "borrar" llama WipeLocalData antes de terminar',
    build: build,
    seed: () =>
        const DeleteAccountState(step: DeleteAccountStep.localDataChoice),
    setUp: () =>
        when(() => wipeLocalData()).thenAnswer((_) async => const Right(unit)),
    act: (cubit) {
      cubit.selectLocalDataChoice(LocalDataChoice.delete);
      return cubit.confirmLocalDataChoice();
    },
    verify: (_) => verify(() => wipeLocalData()).called(1),
    expect: () => [
      const DeleteAccountState(
        step: DeleteAccountStep.localDataChoice,
        choice: LocalDataChoice.delete,
      ),
      const DeleteAccountState(
        step: DeleteAccountStep.localDataChoice,
        status: DeleteAccountStatus.loading,
        choice: LocalDataChoice.delete,
      ),
      const DeleteAccountState(
        step: DeleteAccountStep.done,
        choice: LocalDataChoice.delete,
      ),
    ],
  );

  blocTest<DeleteAccountCubit, DeleteAccountState>(
    'no-dark-pattern: sin elección no pasa nada al confirmar',
    build: build,
    seed: () =>
        const DeleteAccountState(step: DeleteAccountStep.localDataChoice),
    act: (cubit) => cubit.confirmLocalDataChoice(),
    verify: (_) {
      verifyNever(() => wipeLocalData());
    },
    expect: () => <DeleteAccountState>[],
  );

  group('loadScope (HU-07 scope)', () {
    blocTest<DeleteAccountCubit, DeleteAccountState>(
      'expone cloudAndLocal cuando hay sesión activa',
      build: build,
      setUp: () => when(() => getDeleteAccountScope())
          .thenAnswer((_) async => DeleteAccountScope.cloudAndLocal),
      act: (cubit) => cubit.loadScope(),
      expect: () => [
        const DeleteAccountState(scope: DeleteAccountScope.cloudAndLocal),
      ],
      verify: (cubit) {
        expect(cubit.state.isLocalOnlyAfterSignOut, isFalse);
      },
    );

    blocTest<DeleteAccountCubit, DeleteAccountState>(
      'expone localOnlyNeverSignedIn cuando nunca hubo sesión en el '
      'dispositivo',
      build: build,
      setUp: () => when(() => getDeleteAccountScope())
          .thenAnswer((_) async => DeleteAccountScope.localOnlyNeverSignedIn),
      act: (cubit) => cubit.loadScope(),
      expect: () => [
        const DeleteAccountState(
          scope: DeleteAccountScope.localOnlyNeverSignedIn,
        ),
      ],
      verify: (cubit) {
        expect(cubit.state.isLocalOnlyAfterSignOut, isFalse);
      },
    );

    blocTest<DeleteAccountCubit, DeleteAccountState>(
      'expone localOnlySignedOut cuando el dispositivo firmó sesión antes '
      'pero ahora está deslogueado',
      build: build,
      setUp: () => when(() => getDeleteAccountScope())
          .thenAnswer((_) async => DeleteAccountScope.localOnlySignedOut),
      act: (cubit) => cubit.loadScope(),
      expect: () => [
        const DeleteAccountState(scope: DeleteAccountScope.localOnlySignedOut),
      ],
      verify: (cubit) {
        expect(cubit.state.isLocalOnlyAfterSignOut, isTrue);
      },
    );
  });
}
