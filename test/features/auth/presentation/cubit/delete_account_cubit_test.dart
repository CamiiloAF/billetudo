import 'package:billetudo/core/error/result.dart';
import 'package:billetudo/features/auth/domain/entities/local_data_choice.dart';
import 'package:billetudo/features/auth/domain/usecases/delete_account.dart';
import 'package:billetudo/features/auth/domain/usecases/wipe_local_data.dart';
import 'package:billetudo/features/auth/presentation/cubit/delete_account_cubit.dart';
import 'package:billetudo/features/auth/presentation/cubit/delete_account_state.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockDeleteAccount extends Mock implements DeleteAccount {}

class MockWipeLocalData extends Mock implements WipeLocalData {}

void main() {
  late MockDeleteAccount deleteAccount;
  late MockWipeLocalData wipeLocalData;

  setUp(() {
    deleteAccount = MockDeleteAccount();
    wipeLocalData = MockWipeLocalData();
  });

  DeleteAccountCubit build() =>
      DeleteAccountCubit(deleteAccount, wipeLocalData);

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
}
