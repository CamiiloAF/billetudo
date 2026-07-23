import 'package:billetudo/core/error/result.dart';
import 'package:billetudo/features/debts/domain/entities/debt.dart';
import 'package:billetudo/features/debts/domain/entities/debts_summary.dart';
import 'package:billetudo/features/debts/domain/usecases/watch_debts.dart';
import 'package:billetudo/features/debts/presentation/cubit/debts_list_cubit.dart';
import 'package:billetudo/features/debts/presentation/cubit/debts_list_state.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'debts_presentation_fixtures.dart';

class MockWatchDebts extends Mock implements WatchDebts {}

void main() {
  late MockWatchDebts watchDebts;

  final summary = DebtsSummary.from([
    buildDebtWithBalance(
      debt: buildDebt(id: 'd1', direction: DebtDirection.iOwe),
      balance: buildBalance(totalIncreasesMinor: 100000, totalDecreasesMinor: 32000),
    ),
    buildDebtWithBalance(
      debt: buildDebt(id: 'd2', direction: DebtDirection.owedToMe),
      balance: buildBalance(totalIncreasesMinor: 50000, totalDecreasesMinor: 10000),
    ),
  ]);

  setUp(() => watchDebts = MockWatchDebts());

  DebtsListCubit build() => DebtsListCubit(watchDebts);

  blocTest<DebtsListCubit, DebtsListState>(
    'emite loading y luego ready con el resumen',
    setUp: () => when(watchDebts.call)
        .thenAnswer((_) => Stream.value(Right(summary))),
    build: build,
    act: (cubit) => cubit.start(),
    expect: () => [
      isA<DebtsListState>()
          .having((s) => s.status, 'status', DebtsListStatus.loading),
      isA<DebtsListState>()
          .having((s) => s.status, 'status', DebtsListStatus.ready)
          .having((s) => s.summary.debts.length, 'debts', 2)
          .having((s) => s.summary.totals.length, 'totals', 1)
          .having((s) => s.isEmpty, 'isEmpty', false),
    ],
  );

  blocTest<DebtsListCubit, DebtsListState>(
    'una lista vacía queda ready pero isEmpty',
    setUp: () => when(watchDebts.call)
        .thenAnswer((_) => Stream.value(const Right(DebtsSummary.empty))),
    build: build,
    act: (cubit) => cubit.start(),
    skip: 1,
    expect: () => [
      isA<DebtsListState>()
          .having((s) => s.status, 'status', DebtsListStatus.ready)
          .having((s) => s.isEmpty, 'isEmpty', true),
    ],
  );

  blocTest<DebtsListCubit, DebtsListState>(
    'un error del stream lleva a failure con la falla',
    setUp: () => when(watchDebts.call).thenAnswer(
      (_) => Stream.value(const Left(DatabaseFailure('boom'))),
    ),
    build: build,
    act: (cubit) => cubit.start(),
    skip: 1,
    expect: () => [
      isA<DebtsListState>()
          .having((s) => s.status, 'status', DebtsListStatus.failure)
          .having((s) => s.failure, 'failure', isNotNull),
    ],
  );
}
