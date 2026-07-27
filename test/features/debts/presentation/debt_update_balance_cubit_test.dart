import 'package:billetudo/core/error/result.dart';
import 'package:billetudo/features/debts/domain/usecases/update_debt_balance.dart';
import 'package:billetudo/features/debts/presentation/cubit/debt_update_balance_cubit.dart';
import 'package:billetudo/features/debts/presentation/cubit/debt_update_balance_state.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'debts_presentation_fixtures.dart';

class MockUpdateDebtBalance extends Mock implements UpdateDebtBalance {}

void main() {
  late MockUpdateDebtBalance updateDebtBalance;

  setUpAll(() => registerFallbackValue(DateTime(2026)));

  setUp(() => updateDebtBalance = MockUpdateDebtBalance());

  DebtUpdateBalanceCubit build() => DebtUpdateBalanceCubit(updateDebtBalance);

  test('start deja el nuevo saldo igual al estimado (ajuste 0)', () {
    final cubit = build()
      ..start(debt: buildDebt(), currentOutstandingMinor: 42180000);
    expect(cubit.state.targetMinor, 42180000);
    expect(cubit.state.adjustmentMinor, 0);
    expect(cubit.state.status, DebtUpdateBalanceStatus.ready);
  });

  test('adjustmentMinor es negativo cuando el saldo real es menor', () {
    final cubit = build()
      ..start(debt: buildDebt(), currentOutstandingMinor: 42180000)
      ..targetChanged(42000000);
    expect(cubit.state.adjustmentMinor, -180000);
  });

  blocTest<DebtUpdateBalanceCubit, DebtUpdateBalanceState>(
    'submit registra el ajuste de reconciliación y llega a saved',
    setUp: () => when(() => updateDebtBalance.call(
          debtId: any(named: 'debtId'),
          targetOutstandingMinor: any(named: 'targetOutstandingMinor'),
          date: any(named: 'date'),
          note: any(named: 'note'),
        )).thenAnswer((_) async => Right(buildEntry())),
    build: build,
    act: (cubit) async {
      cubit
        ..start(debt: buildDebt(), currentOutstandingMinor: 42180000)
        ..targetChanged(42000000);
      await cubit.submit();
    },
    skip: 2,
    expect: () => [
      isA<DebtUpdateBalanceState>()
          .having((s) => s.status, 'status', DebtUpdateBalanceStatus.saving),
      isA<DebtUpdateBalanceState>()
          .having((s) => s.status, 'status', DebtUpdateBalanceStatus.saved),
    ],
    verify: (_) => verify(() => updateDebtBalance.call(
          debtId: 'd1',
          targetOutstandingMinor: 42000000,
          date: any(named: 'date'),
          note: any(named: 'note'),
        )).called(1),
  );
}
