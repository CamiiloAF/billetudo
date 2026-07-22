import 'package:billetudo/core/error/result.dart';
import 'package:billetudo/features/accounts/domain/entities/account_balance_adjustment.dart';
import 'package:billetudo/features/accounts/domain/usecases/adjust_account_balance.dart';
import 'package:billetudo/features/accounts/presentation/cubit/adjust_balance_cubit.dart';
import 'package:billetudo/features/accounts/presentation/cubit/adjust_balance_state.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../account_fixtures.dart';

class MockAdjustAccountBalance extends Mock implements AdjustAccountBalance {}

void main() {
  late MockAdjustAccountBalance adjust;

  setUpAll(() {
    registerFallbackValue(buildAccount());
    registerFallbackValue(BalanceAdjustmentMode.registerMovement);
  });

  setUp(() {
    adjust = MockAdjustAccountBalance();
    when(
      () => adjust(
        account: any(named: 'account'),
        currentBalanceMinor: any(named: 'currentBalanceMinor'),
        newDisplayedBalanceMinor: any(named: 'newDisplayedBalanceMinor'),
        mode: any(named: 'mode'),
        note: any(named: 'note'),
      ),
    ).thenAnswer((_) async => const Right(unit));
  });

  AdjustBalanceCubit build() => AdjustBalanceCubit(adjust);

  final account = buildAccount(initialBalanceMinor: 0);

  test('start fija cuenta y saldo actual, estado editing', () async {
    final cubit = build()
      ..start(account: account, currentBalanceMinor: 100000);
    addTearDown(cubit.close);

    expect(cubit.state.status, AdjustBalanceStatus.editing);
    expect(cubit.state.account, account);
    expect(cubit.state.currentBalanceMinor, 100000);
    expect(cubit.state.mode, BalanceAdjustmentMode.registerMovement);
    // Sin cifra tecleada no se puede aplicar.
    expect(cubit.state.canApply, isFalse);
  });

  blocTest<AdjustBalanceCubit, AdjustBalanceState>(
    'modeSelected cambia el modo',
    build: build,
    seed: () => AdjustBalanceState(
      account: account,
      currentBalanceMinor: 100000,
    ),
    act: (cubit) => cubit.modeSelected(BalanceAdjustmentMode.correctInitial),
    expect: () => [
      isA<AdjustBalanceState>().having(
        (s) => s.mode,
        'mode',
        BalanceAdjustmentMode.correctInitial,
      ),
    ],
  );

  blocTest<AdjustBalanceCubit, AdjustBalanceState>(
    'apply exitoso emite saving y luego saved',
    build: build,
    seed: () => AdjustBalanceState(
      account: account,
      currentBalanceMinor: 100000,
      newBalanceText: '5000',
    ),
    act: (cubit) => cubit.apply(note: 'Ajuste de saldo'),
    expect: () => [
      isA<AdjustBalanceState>()
          .having((s) => s.status, 'status', AdjustBalanceStatus.saving),
      isA<AdjustBalanceState>()
          .having((s) => s.status, 'status', AdjustBalanceStatus.saved),
    ],
    verify: (_) {
      verify(
        () => adjust(
          account: account,
          currentBalanceMinor: 100000,
          newDisplayedBalanceMinor: any(named: 'newDisplayedBalanceMinor'),
          mode: BalanceAdjustmentMode.registerMovement,
          note: any(named: 'note'),
        ),
      ).called(1);
    },
  );

  blocTest<AdjustBalanceCubit, AdjustBalanceState>(
    'apply con fallo emite saving y luego failure',
    build: () {
      when(
        () => adjust(
          account: any(named: 'account'),
          currentBalanceMinor: any(named: 'currentBalanceMinor'),
          newDisplayedBalanceMinor: any(named: 'newDisplayedBalanceMinor'),
          mode: any(named: 'mode'),
          note: any(named: 'note'),
        ),
      ).thenAnswer((_) async => const Left(DatabaseFailure('nope')));
      return build();
    },
    seed: () => AdjustBalanceState(
      account: account,
      currentBalanceMinor: 100000,
      newBalanceText: '5000',
    ),
    act: (cubit) => cubit.apply(note: 'Ajuste de saldo'),
    expect: () => [
      isA<AdjustBalanceState>()
          .having((s) => s.status, 'status', AdjustBalanceStatus.saving),
      isA<AdjustBalanceState>()
          .having((s) => s.status, 'status', AdjustBalanceStatus.failure),
    ],
  );

  blocTest<AdjustBalanceCubit, AdjustBalanceState>(
    'apply sin cambio no llama al caso de uso',
    build: build,
    seed: () => AdjustBalanceState(
      account: account,
      currentBalanceMinor: 100000,
      // Vacío: no hay cifra, no puede aplicar.
    ),
    act: (cubit) => cubit.apply(note: 'Ajuste de saldo'),
    expect: () => <AdjustBalanceState>[],
    verify: (_) {
      verifyNever(
        () => adjust(
          account: any(named: 'account'),
          currentBalanceMinor: any(named: 'currentBalanceMinor'),
          newDisplayedBalanceMinor: any(named: 'newDisplayedBalanceMinor'),
          mode: any(named: 'mode'),
          note: any(named: 'note'),
        ),
      );
    },
  );
}
