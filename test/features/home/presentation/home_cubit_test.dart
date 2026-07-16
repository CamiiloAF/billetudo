import 'dart:async';

import 'package:billetudo/core/error/result.dart';
import 'package:billetudo/features/accounts/domain/entities/account_with_balance.dart';
import 'package:billetudo/features/accounts/domain/usecases/watch_accounts.dart';
import 'package:billetudo/features/home/domain/usecases/watch_month_transactions.dart';
import 'package:billetudo/features/home/presentation/cubit/home_cubit.dart';
import 'package:billetudo/features/home/presentation/cubit/home_state.dart';
import 'package:billetudo/features/transactions/domain/entities/transaction_with_details.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../home_fixtures.dart';

class MockWatchAccounts extends Mock implements WatchAccounts {}

class MockWatchMonthTransactions extends Mock
    implements WatchMonthTransactions {}

void main() {
  late MockWatchAccounts watchAccounts;
  late MockWatchMonthTransactions watchMonthTransactions;

  final accounts = [buildActiveAccount()];
  final activity = [buildActivity(amountMinor: 82000)];

  setUpAll(() => registerFallbackValue(DateTime(2026)));

  setUp(() {
    watchAccounts = MockWatchAccounts();
    watchMonthTransactions = MockWatchMonthTransactions();
  });

  HomeCubit build() => HomeCubit(watchAccounts, watchMonthTransactions);

  void stubReady() {
    when(() => watchAccounts()).thenAnswer(
      (_) => Stream<Result<List<AccountWithBalance>>>.value(Right(accounts)),
    );
    when(() => watchMonthTransactions(any())).thenAnswer(
      (_) =>
          Stream<Result<List<TransactionWithDetails>>>.value(Right(activity)),
    );
  }

  blocTest<HomeCubit, HomeState>(
    'combina cuentas + transacciones y emite ready con el gasto del mes',
    setUp: stubReady,
    build: build,
    act: (cubit) => cubit.start(),
    verify: (cubit) {
      expect(cubit.state.status, HomeStatus.ready);
      expect(cubit.state.spending?.displayTotalMinor, 82000);
      expect(cubit.state.recentActivity, hasLength(1));
      expect(cubit.state.isEmpty, isFalse);
    },
  );

  blocTest<HomeCubit, HomeState>(
    'espera a ambos streams antes de salir de loading',
    setUp: () {
      when(() => watchAccounts()).thenAnswer(
        (_) => Stream<Result<List<AccountWithBalance>>>.value(Right(accounts)),
      );
      // Transactions never emit: the cubit must stay loading.
      when(() => watchMonthTransactions(any())).thenAnswer(
        (_) => const Stream<Result<List<TransactionWithDetails>>>.empty(),
      );
    },
    build: build,
    act: (cubit) => cubit.start(),
    verify: (cubit) => expect(cubit.state.status, HomeStatus.loading),
  );

  blocTest<HomeCubit, HomeState>(
    'un fallo de cualquier stream deja el estado en failure (HU-10)',
    setUp: () {
      when(() => watchAccounts()).thenAnswer(
        (_) => Stream<Result<List<AccountWithBalance>>>.value(Right(accounts)),
      );
      when(() => watchMonthTransactions(any())).thenAnswer(
        (_) => Stream<Result<List<TransactionWithDetails>>>.value(
          const Left(DatabaseFailure('boom')),
        ),
      );
    },
    build: build,
    act: (cubit) => cubit.start(),
    verify: (cubit) => expect(cubit.state.status, HomeStatus.failure),
  );

  blocTest<HomeCubit, HomeState>(
    'sin movimientos: ready y vacío (HU-08)',
    setUp: () {
      when(() => watchAccounts()).thenAnswer(
        (_) => Stream<Result<List<AccountWithBalance>>>.value(Right(accounts)),
      );
      when(() => watchMonthTransactions(any())).thenAnswer(
        (_) => Stream<Result<List<TransactionWithDetails>>>.value(
          const Right(<TransactionWithDetails>[]),
        ),
      );
    },
    build: build,
    act: (cubit) => cubit.start(),
    verify: (cubit) {
      expect(cubit.state.status, HomeStatus.ready);
      expect(cubit.state.isEmpty, isTrue);
    },
  );

  blocTest<HomeCubit, HomeState>(
    'cambiar a un mes pasado re-suscribe las transacciones (HU-04)',
    setUp: stubReady,
    build: build,
    act: (cubit) async {
      await cubit.start();
      await cubit.selectMonth(DateTime(2026));
    },
    verify: (cubit) {
      expect(cubit.state.month, DateTime(2026));
      verify(() => watchMonthTransactions(any())).called(2);
    },
  );

  blocTest<HomeCubit, HomeState>(
    'seleccionar el mismo mes no re-suscribe las transacciones (HU-04)',
    setUp: stubReady,
    build: build,
    act: (cubit) async {
      await cubit.start();
      await cubit.selectMonth(cubit.state.currentMonth);
    },
    verify: (cubit) {
      // Same month is a no-op: only the initial subscription happened.
      verify(() => watchMonthTransactions(any())).called(1);
      expect(cubit.state.status, HomeStatus.ready);
    },
  );

  blocTest<HomeCubit, HomeState>(
    'cambiar de mes pasa por loading antes de traer el nuevo mes (HU-04)',
    setUp: () {
      when(() => watchAccounts()).thenAnswer(
        (_) => Stream<Result<List<AccountWithBalance>>>.value(Right(accounts)),
      );
      // First subscription lands data; the second (past month) never emits, so
      // the cubit is caught mid-transition in loading.
      var call = 0;
      when(() => watchMonthTransactions(any())).thenAnswer((_) {
        call++;
        return call == 1
            ? Stream<Result<List<TransactionWithDetails>>>.value(Right(activity))
            : const Stream<Result<List<TransactionWithDetails>>>.empty();
      });
    },
    build: build,
    act: (cubit) async {
      await cubit.start();
      await cubit.selectMonth(DateTime(2026));
    },
    verify: (cubit) {
      expect(cubit.state.month, DateTime(2026));
      expect(cubit.state.status, HomeStatus.loading);
    },
  );

  blocTest<HomeCubit, HomeState>(
    'el mes por defecto es el mes en curso (HU-04)',
    setUp: stubReady,
    build: build,
    verify: (cubit) {
      final now = DateTime.now();
      expect(cubit.state.month, DateTime(now.year, now.month));
      expect(cubit.state.currentMonth, cubit.state.month);
      expect(cubit.state.syncStatus, HomeSyncStatus.synced);
    },
  );

  blocTest<HomeCubit, HomeState>(
    'no navega a un mes futuro (HU-04)',
    setUp: stubReady,
    build: build,
    act: (cubit) async {
      await cubit.start();
      final future = DateTime(cubit.state.currentMonth.year + 1);
      await cubit.selectMonth(future);
    },
    verify: (cubit) {
      expect(cubit.state.month, cubit.state.currentMonth);
      verify(() => watchMonthTransactions(any())).called(1);
    },
  );

  test('cerrar el cubit cancela ambas suscripciones', () async {
    final accountsController =
        StreamController<Result<List<AccountWithBalance>>>.broadcast();
    final txController =
        StreamController<Result<List<TransactionWithDetails>>>.broadcast();
    when(() => watchAccounts()).thenAnswer((_) => accountsController.stream);
    when(() => watchMonthTransactions(any()))
        .thenAnswer((_) => txController.stream);

    final cubit = build();
    await cubit.start();
    await cubit.close();

    expect(accountsController.hasListener, isFalse);
    expect(txController.hasListener, isFalse);
    await accountsController.close();
    await txController.close();
  });
}
