import 'dart:async';

import 'package:billetudo/core/error/result.dart';
import 'package:billetudo/features/transactions/presentation/cubit/account_filter_cubit.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../accounts/account_fixtures.dart';
import 'usecase_mocks.dart';

void main() {
  late MockWatchAccounts watchAccounts;

  final bank = buildAccount(id: 'a', name: 'Bancolombia');
  final cash = buildAccount(id: 'b', name: 'Efectivo');
  final entries = [
    buildAccountWithBalance(account: bank, balanceMinor: 1000),
    buildAccountWithBalance(account: cash, balanceMinor: 500),
  ];

  setUp(() {
    watchAccounts = MockWatchAccounts();
    when(() => watchAccounts()).thenAnswer((_) => Stream.value(Right(entries)));
  });

  AccountFilterCubit build() => AccountFilterCubit(watchAccounts);

  blocTest<AccountFilterCubit, AccountFilterState>(
    'arranca con la selección inicial y carga las cuentas',
    build: build,
    act: (cubit) async {
      await cubit.start({'a'});
      await Future<void>.delayed(Duration.zero);
    },
    verify: (cubit) {
      expect(cubit.state.selected, {'a'});
      expect(cubit.state.accounts, entries);
    },
  );

  blocTest<AccountFilterCubit, AccountFilterState>(
    'alternar una cuenta la agrega o la quita',
    build: build,
    act: (cubit) async {
      await cubit.start(const {});
      cubit.toggle('a');
      cubit.toggle('a');
    },
    verify: (cubit) => expect(cubit.state.selected, isEmpty),
  );

  blocTest<AccountFilterCubit, AccountFilterState>(
    'Todas marca cada cuenta (HU-06a: vacío = todas, sin badge)',
    build: build,
    act: (cubit) async {
      await cubit.start(const {});
      await Future<void>.delayed(Duration.zero);
      cubit.selectAll();
    },
    verify: (cubit) => expect(cubit.state.selected, {'a', 'b'}),
  );

  blocTest<AccountFilterCubit, AccountFilterState>(
    'Ninguna limpia la selección, sin importar cuántas estaban marcadas',
    build: build,
    act: (cubit) async {
      await cubit.start(const {});
      await Future<void>.delayed(Duration.zero);
      cubit.selectAll();
      cubit.selectNone();
    },
    verify: (cubit) => expect(cubit.state.selected, isEmpty),
  );

  blocTest<AccountFilterCubit, AccountFilterState>(
    'si el stream de cuentas falla, el estado pasa a failure con el Failure',
    build: build,
    setUp: () {
      when(() => watchAccounts()).thenAnswer(
        (_) => Stream.value(const Left(DatabaseFailure('sin disco'))),
      );
    },
    act: (cubit) async {
      await cubit.start(const {});
      await Future<void>.delayed(Duration.zero);
    },
    verify: (cubit) {
      expect(cubit.state.status, AccountFilterStatus.failure);
      expect(cubit.state.failure, isA<DatabaseFailure>());
    },
  );

  blocTest<AccountFilterCubit, AccountFilterState>(
    'reabrir el sheet cancela la suscripción anterior antes de crear otra',
    build: build,
    act: (cubit) async {
      await cubit.start({'a'});
      await cubit.start({'b'});
      await Future<void>.delayed(Duration.zero);
    },
    verify: (cubit) => expect(cubit.state.selected, {'b'}),
  );
}
