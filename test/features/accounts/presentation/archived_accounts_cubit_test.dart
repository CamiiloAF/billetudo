import 'package:billetudo/core/error/result.dart';
import 'package:billetudo/features/accounts/domain/entities/account_with_balance.dart';
import 'package:billetudo/features/accounts/presentation/cubit/archived_accounts_cubit.dart';
import 'package:billetudo/features/accounts/presentation/cubit/archived_accounts_state.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../account_fixtures.dart';
import 'usecase_mocks.dart';

void main() {
  late MockWatchArchivedAccounts watchArchived;
  late MockUnarchiveAccount unarchiveAccount;

  final archived =
      buildAccount(id: 'old-1', name: 'Cuenta vieja', archived: true);
  final entries = [buildAccountWithBalance(account: archived, balanceMinor: 0)];

  setUp(() {
    watchArchived = MockWatchArchivedAccounts();
    unarchiveAccount = MockUnarchiveAccount();
  });

  ArchivedAccountsCubit build() =>
      ArchivedAccountsCubit(watchArchived, unarchiveAccount);

  blocTest<ArchivedAccountsCubit, ArchivedAccountsState>(
    'emite las cuentas archivadas',
    setUp: () => when(watchArchived.call)
        .thenAnswer((_) => Stream.value(Right(entries))),
    build: build,
    act: (cubit) => cubit.start(),
    expect: () => [
      const ArchivedAccountsState(),
      ArchivedAccountsState(
        status: ArchivedAccountsStatus.ready,
        accounts: entries,
      ),
    ],
  );

  blocTest<ArchivedAccountsCubit, ArchivedAccountsState>(
    'sin archivadas, el estado vacío es explícito',
    setUp: () => when(watchArchived.call)
        .thenAnswer((_) => Stream.value(const Right(<AccountWithBalance>[]))),
    build: build,
    act: (cubit) => cubit.start(),
    verify: (cubit) => expect(cubit.state.isEmpty, isTrue),
  );

  blocTest<ArchivedAccountsCubit, ArchivedAccountsState>(
    'desarchivar delega en el caso de uso: la cuenta sale del stream sola',
    setUp: () {
      when(watchArchived.call).thenAnswer((_) => Stream.value(Right(entries)));
      when(() => unarchiveAccount(any()))
          .thenAnswer((_) async => const Right(unit));
    },
    build: build,
    act: (cubit) async {
      await cubit.start();
      await cubit.unarchive('old-1');
    },
    verify: (cubit) {
      verify(() => unarchiveAccount('old-1')).called(1);
      expect(cubit.state.status, ArchivedAccountsStatus.ready);
    },
  );

  blocTest<ArchivedAccountsCubit, ArchivedAccountsState>(
    'un fallo al desarchivar queda visible',
    setUp: () {
      when(watchArchived.call).thenAnswer((_) => Stream.value(Right(entries)));
      when(() => unarchiveAccount(any()))
          .thenAnswer((_) async => const Left(DatabaseFailure('boom')));
    },
    build: build,
    act: (cubit) async {
      await cubit.start();
      await cubit.unarchive('old-1');
    },
    verify: (cubit) {
      expect(cubit.state.status, ArchivedAccountsStatus.failure);
      expect(cubit.state.failure, isA<DatabaseFailure>());
    },
  );

  blocTest<ArchivedAccountsCubit, ArchivedAccountsState>(
    'un fallo del stream deja el estado de error',
    setUp: () => when(watchArchived.call)
        .thenAnswer((_) => Stream.value(const Left(DatabaseFailure('boom')))),
    build: build,
    act: (cubit) => cubit.start(),
    verify: (cubit) =>
        expect(cubit.state.status, ArchivedAccountsStatus.failure),
  );
}
