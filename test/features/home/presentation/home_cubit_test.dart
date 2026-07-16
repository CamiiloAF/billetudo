import 'dart:async';

import 'package:billetudo/core/error/result.dart';
import 'package:billetudo/features/accounts/domain/entities/account_with_balance.dart';
import 'package:billetudo/features/accounts/domain/usecases/watch_accounts.dart';
import 'package:billetudo/features/auth/domain/entities/auth_provider.dart';
import 'package:billetudo/features/auth/domain/entities/auth_session.dart';
import 'package:billetudo/features/auth/domain/entities/auth_user.dart';
import 'package:billetudo/features/auth/domain/usecases/watch_auth_session.dart';
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

class MockWatchAuthSession extends Mock implements WatchAuthSession {}

void main() {
  late MockWatchAccounts watchAccounts;
  late MockWatchMonthTransactions watchMonthTransactions;
  late MockWatchAuthSession watchAuthSession;

  final accounts = [buildActiveAccount()];
  final activity = [buildActivity(amountMinor: 82000)];
  const user = AuthUser(
    id: 'u-1',
    displayName: 'Camila',
    provider: AuthProvider.google,
  );

  setUpAll(() => registerFallbackValue(DateTime(2026)));

  setUp(() {
    watchAccounts = MockWatchAccounts();
    watchMonthTransactions = MockWatchMonthTransactions();
    watchAuthSession = MockWatchAuthSession();
    // Default: signed out; individual tests override to emit a session.
    when(() => watchAuthSession())
        .thenAnswer((_) => const Stream<AuthSession>.empty());
  });

  HomeCubit build() =>
      HomeCubit(watchAccounts, watchMonthTransactions, watchAuthSession);

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

  blocTest<HomeCubit, HomeState>(
    'la sesión con nombre puebla user sin gatear el status (HU-07)',
    setUp: () {
      stubReady();
      when(() => watchAuthSession()).thenAnswer(
        (_) => Stream<AuthSession>.value(const AuthSession.signedIn(user)),
      );
    },
    build: build,
    act: (cubit) => cubit.start(),
    verify: (cubit) {
      expect(cubit.state.user, user);
      // The status still depends only on accounts + transactions.
      expect(cubit.state.status, HomeStatus.ready);
    },
  );

  blocTest<HomeCubit, HomeState>(
    'cerrar sesión limpia user a null (HU-07)',
    setUp: () {
      stubReady();
      when(() => watchAuthSession()).thenAnswer(
        (_) => Stream<AuthSession>.fromIterable(const [
          AuthSession.signedIn(user),
          AuthSession.signedOut(),
        ]),
      );
    },
    build: build,
    act: (cubit) => cubit.start(),
    verify: (cubit) => expect(cubit.state.user, isNull),
  );

  blocTest<HomeCubit, HomeState>(
    'sin sesión: user queda null (local-first, HU-07)',
    setUp: stubReady,
    build: build,
    act: (cubit) => cubit.start(),
    verify: (cubit) => expect(cubit.state.user, isNull),
  );

  test('cerrar el cubit cancela las tres suscripciones', () async {
    final accountsController =
        StreamController<Result<List<AccountWithBalance>>>.broadcast();
    final txController =
        StreamController<Result<List<TransactionWithDetails>>>.broadcast();
    final authController = StreamController<AuthSession>.broadcast();
    when(() => watchAccounts()).thenAnswer((_) => accountsController.stream);
    when(() => watchMonthTransactions(any()))
        .thenAnswer((_) => txController.stream);
    when(() => watchAuthSession()).thenAnswer((_) => authController.stream);

    final cubit = build();
    await cubit.start();
    await cubit.close();

    expect(accountsController.hasListener, isFalse);
    expect(txController.hasListener, isFalse);
    expect(authController.hasListener, isFalse);
    await accountsController.close();
    await txController.close();
    await authController.close();
  });
}
