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
    when(() => watchAccounts())
        .thenAnswer((_) => Stream.value(Right(entries)));
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
    'Todas marca cada cuenta y Ninguna limpia la selección (HU-06a: vacío = todas, sin badge)',
    build: build,
    act: (cubit) async {
      await cubit.start(const {});
      await Future<void>.delayed(Duration.zero);
      cubit.selectAll();
    },
    verify: (cubit) => expect(cubit.state.selected, {'a', 'b'}),
  );
}
