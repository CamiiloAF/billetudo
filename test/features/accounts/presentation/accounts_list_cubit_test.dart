import 'dart:async';

import 'package:billetudo/core/error/result.dart';
import 'package:billetudo/features/accounts/domain/entities/account.dart';
import 'package:billetudo/features/accounts/domain/entities/account_with_balance.dart';
import 'package:billetudo/features/accounts/domain/entities/accounts_overview.dart';
import 'package:billetudo/features/accounts/presentation/cubit/accounts_list_cubit.dart';
import 'package:billetudo/features/accounts/presentation/cubit/accounts_list_state.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../account_fixtures.dart';
import 'usecase_mocks.dart';

void main() {
  late MockWatchAccounts watchAccounts;
  late MockWatchAccountsOverview watchOverview;
  late MockReorderAccounts reorderAccounts;

  final bank = buildAccount(id: 'a', name: 'Bancolombia');
  final cash = buildAccount(
    id: 'b',
    name: 'Efectivo',
    type: AccountType.cash,
    sortOrder: 1,
  );
  final entries = [
    buildAccountWithBalance(account: bank, balanceMinor: 500000),
    buildAccountWithBalance(account: cash, balanceMinor: 20000),
  ];

  setUpAll(registerPresentationFallbacks);

  setUp(() {
    watchAccounts = MockWatchAccounts();
    watchOverview = MockWatchAccountsOverview();
    reorderAccounts = MockReorderAccounts();
  });

  AccountsListCubit build() =>
      AccountsListCubit(watchAccounts, watchOverview, reorderAccounts);

  void stubStreams({
    required Stream<Result<List<AccountWithBalance>>> accounts,
    Stream<Result<AccountsOverview>>? overview,
  }) {
    when(watchAccounts.call).thenAnswer((_) => accounts);
    when(watchOverview.call).thenAnswer(
      (_) => overview ?? const Stream<Result<AccountsOverview>>.empty(),
    );
  }

  group('carga inicial', () {
    blocTest<AccountsListCubit, AccountsListState>(
      'emite los datos y el resumen cuando llegan las cuentas',
      setUp: () => stubStreams(
        accounts: Stream.value(Right(entries)),
        overview: Stream.value(Right(AccountsOverview.from(entries))),
      ),
      build: build,
      act: (cubit) => cubit.start(),
      expect: () => [
        const AccountsListState(),
        AccountsListState(
          status: AccountsListStatus.ready,
          accounts: entries,
        ),
        AccountsListState(
          status: AccountsListStatus.ready,
          accounts: entries,
          overview: AccountsOverview.from(entries),
        ),
      ],
    );

    blocTest<AccountsListCubit, AccountsListState>(
      'una lista vacía queda en ready, no en carga: isEmpty es su propio estado',
      setUp: () => stubStreams(
        accounts: Stream.value(const Right(<AccountWithBalance>[])),
      ),
      build: build,
      act: (cubit) => cubit.start(),
      verify: (cubit) {
        expect(cubit.state.isEmpty, isTrue);
        expect(cubit.state.isLoading, isFalse);
      },
    );

    blocTest<AccountsListCubit, AccountsListState>(
      'un fallo del stream deja el estado de error',
      setUp: () => stubStreams(
        accounts: Stream.value(const Left(DatabaseFailure('boom'))),
      ),
      build: build,
      act: (cubit) => cubit.start(),
      verify: (cubit) {
        expect(cubit.state.status, AccountsListStatus.failure);
        expect(cubit.state.failure, isA<DatabaseFailure>());
      },
    );

    blocTest<AccountsListCubit, AccountsListState>(
      'reintentar tras un error vuelve a suscribirse y muestra los datos',
      setUp: () {
        var firstCall = true;
        when(watchAccounts.call).thenAnswer((_) {
          if (firstCall) {
            firstCall = false;
            return Stream.value(const Left(DatabaseFailure('boom')));
          }
          return Stream.value(Right(entries));
        });
        when(watchOverview.call).thenAnswer(
          (_) => const Stream<Result<AccountsOverview>>.empty(),
        );
      },
      build: build,
      act: (cubit) async {
        await cubit.start();
        await Future<void>.delayed(Duration.zero);
        await cubit.start();
      },
      verify: (cubit) {
        expect(cubit.state.status, AccountsListStatus.ready);
        expect(cubit.state.accounts, entries);
      },
    );
  });

  group('reordenar (HU-09)', () {
    blocTest<AccountsListCubit, AccountsListState>(
      'persiste el nuevo orden de ids y lo refleja de inmediato',
      setUp: () {
        stubStreams(accounts: Stream.value(Right(entries)));
        when(() => reorderAccounts(any()))
            .thenAnswer((_) async => const Right(unit));
      },
      build: build,
      act: (cubit) async {
        await cubit.start();
        await Future<void>.delayed(Duration.zero);
        // Raw SliverReorderableList indices: dropping the first row past the
        // end of a 2-row list reports newIndex 2 (the pre-removal insertion
        // point), not 1 — the cubit does the oldIndex<newIndex adjustment.
        await cubit.reorder(0, 2);
      },
      verify: (cubit) {
        // La UI no espera al stream: la fila se queda donde el usuario la soltó.
        expect(
          [for (final e in cubit.state.accounts) e.account.id],
          ['b', 'a'],
        );
        verify(() => reorderAccounts(['b', 'a'])).called(1);
      },
    );

    blocTest<AccountsListCubit, AccountsListState>(
      'soltar la fila en su misma posición no escribe nada',
      setUp: () => stubStreams(accounts: Stream.value(Right(entries))),
      build: build,
      act: (cubit) async {
        await cubit.start();
        await Future<void>.delayed(Duration.zero);
        await cubit.reorder(1, 1);
      },
      verify: (_) => verifyNever(() => reorderAccounts(any())),
    );

    blocTest<AccountsListCubit, AccountsListState>(
      'si la escritura falla, el error queda visible',
      setUp: () {
        stubStreams(accounts: Stream.value(Right(entries)));
        when(() => reorderAccounts(any()))
            .thenAnswer((_) async => const Left(DatabaseFailure('boom')));
      },
      build: build,
      act: (cubit) async {
        await cubit.start();
        await Future<void>.delayed(Duration.zero);
        await cubit.reorder(0, 2);
      },
      verify: (cubit) => expect(cubit.state.status, AccountsListStatus.failure),
    );
  });

  test('cerrar el cubit cancela la suscripción al stream', () async {
    final controller =
        StreamController<Result<List<AccountWithBalance>>>.broadcast();
    stubStreams(accounts: controller.stream);

    final cubit = build();
    await cubit.start();
    await cubit.close();

    expect(controller.hasListener, isFalse);
    await controller.close();
  });
}
