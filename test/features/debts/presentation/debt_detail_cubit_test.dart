import 'package:billetudo/core/error/result.dart';
import 'package:billetudo/features/debts/domain/entities/debt.dart';
import 'package:billetudo/features/debts/domain/entities/debt_detail.dart';
import 'package:billetudo/features/debts/domain/entities/debt_ledger_entry.dart';
import 'package:billetudo/features/debts/domain/services/debt_interest_calculator.dart';
import 'package:billetudo/features/debts/domain/usecases/watch_debt_detail.dart';
import 'package:billetudo/features/debts/presentation/cubit/debt_detail_cubit.dart';
import 'package:billetudo/features/debts/presentation/cubit/debt_detail_state.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'debts_presentation_fixtures.dart';

class MockWatchDebtDetail extends Mock implements WatchDebtDetail {}

void main() {
  late MockWatchDebtDetail watchDebtDetail;

  const calculator = DebtInterestCalculator();

  final ledger = [
    buildLedgerEntry(
      id: 'pay',
      kind: DebtLedgerKind.cashPayment,
      effectMinor: -32000,
      transactionId: 't1',
    ),
    buildLedgerEntry(
      id: 'open',
      kind: DebtLedgerKind.opening,
      effectMinor: 100000,
    ),
  ];

  DebtDetail detailWith(Debt debt) => buildDebtDetail(
        debt: debt,
        balance: buildBalance(
          principalMinor: 100000,
          totalIncreasesMinor: 100000,
          totalDecreasesMinor: 32000,
        ),
        ledger: ledger,
      );

  setUp(() => watchDebtDetail = MockWatchDebtDetail());

  DebtDetailCubit build() => DebtDetailCubit(watchDebtDetail, calculator);

  blocTest<DebtDetailCubit, DebtDetailState>(
    'ready: expone el saldo corrido por fila, del más nuevo al más viejo',
    setUp: () => when(() => watchDebtDetail.call(any())).thenAnswer(
      (_) => Stream.value(Right(detailWith(buildDebt()))),
    ),
    build: build,
    act: (cubit) => cubit.start('d1'),
    skip: 1,
    expect: () => [
      isA<DebtDetailState>()
          .having((s) => s.status, 'status', DebtDetailStatus.ready)
          .having((s) => s.runningBalances, 'running', [68000, 100000])
          .having((s) => s.dailyGrowthMinor, 'growth', isNull),
    ],
  );

  blocTest<DebtDetailCubit, DebtDetailState>(
    'ready: una deuda de interés automático estima el crecimiento diario',
    setUp: () => when(() => watchDebtDetail.call(any())).thenAnswer(
      (_) => Stream.value(
        Right(
          detailWith(
            buildDebt(
              accrualMode: DebtAccrualMode.auto,
              interestRateBps: 3650,
            ),
          ),
        ),
      ),
    ),
    build: build,
    act: (cubit) => cubit.start('d1'),
    skip: 1,
    expect: () => [
      isA<DebtDetailState>()
          .having((s) => s.status, 'status', DebtDetailStatus.ready)
          .having(
            (s) => (s.dailyGrowthMinor ?? 0) > 0,
            'growth > 0',
            true,
          ),
    ],
  );

  blocTest<DebtDetailCubit, DebtDetailState>(
    'HU-03: expone la cuota enlazada como installment view',
    setUp: () => when(() => watchDebtDetail.call(any())).thenAnswer(
      (_) => Stream.value(
        Right(
          buildDebtDetail(
            debt: buildDebt(),
            balance: buildBalance(principalMinor: 100000),
            ledger: ledger,
            installment: buildDebtInstallment(
              scheduledPaymentId: 'sp-9',
              amountMinor: 68000000,
              nextDate: DateTime(2026, 8, 13),
            ),
          ),
        ),
      ),
    ),
    build: build,
    act: (cubit) => cubit.start('d1'),
    skip: 1,
    expect: () => [
      isA<DebtDetailState>()
          .having((s) => s.status, 'status', DebtDetailStatus.ready)
          .having(
            (s) => s.installment?.scheduledPaymentId,
            'installment sp id',
            'sp-9',
          )
          .having(
            (s) => s.installment?.amountMinor,
            'installment amount',
            68000000,
          )
          .having(
            (s) => s.installment?.date,
            'installment date',
            DateTime(2026, 8, 13),
          ),
    ],
  );

  blocTest<DebtDetailCubit, DebtDetailState>(
    'sin cuota configurada, installment queda en null',
    setUp: () => when(() => watchDebtDetail.call(any())).thenAnswer(
      (_) => Stream.value(Right(detailWith(buildDebt()))),
    ),
    build: build,
    act: (cubit) => cubit.start('d1'),
    skip: 1,
    expect: () => [
      isA<DebtDetailState>()
          .having((s) => s.status, 'status', DebtDetailStatus.ready)
          .having((s) => s.installment, 'installment', isNull),
    ],
  );

  blocTest<DebtDetailCubit, DebtDetailState>(
    'un error del stream lleva a failure',
    setUp: () => when(() => watchDebtDetail.call(any())).thenAnswer(
      (_) => Stream.value(const Left(NotFoundFailure('missing'))),
    ),
    build: build,
    act: (cubit) => cubit.start('d1'),
    skip: 1,
    expect: () => [
      isA<DebtDetailState>()
          .having((s) => s.status, 'status', DebtDetailStatus.failure),
    ],
  );
}
