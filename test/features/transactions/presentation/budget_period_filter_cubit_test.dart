import 'dart:async';

import 'package:billetudo/core/error/result.dart';
import 'package:billetudo/features/transactions/domain/entities/budget_period_option.dart';
import 'package:billetudo/features/transactions/presentation/cubit/budget_period_filter_cubit.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'usecase_mocks.dart';

void main() {
  late MockWatchBudgetPeriodOptions watchBudgetPeriodOptions;

  final food = BudgetPeriodOption(
    budgetId: 'a',
    name: 'Comida',
    icon: 'utensils',
    start: DateTime(2026, 7),
    endExclusive: DateTime(2026, 8),
  );
  final transport = BudgetPeriodOption(
    budgetId: 'b',
    name: 'Transporte',
    start: DateTime(2026, 7),
    endExclusive: DateTime(2026, 8),
  );
  final options = [food, transport];

  setUp(() {
    watchBudgetPeriodOptions = MockWatchBudgetPeriodOptions();
    when(() => watchBudgetPeriodOptions())
        .thenAnswer((_) => Stream.value(Right(options)));
  });

  BudgetPeriodFilterCubit build() =>
      BudgetPeriodFilterCubit(watchBudgetPeriodOptions);

  blocTest<BudgetPeriodFilterCubit, BudgetPeriodFilterState>(
    'arranca con la selección inicial y carga los presupuestos activos',
    build: build,
    act: (cubit) async {
      await cubit.start('a');
      await Future<void>.delayed(Duration.zero);
    },
    verify: (cubit) {
      expect(cubit.state.selectedBudgetId, 'a');
      expect(cubit.state.options, options);
      expect(cubit.state.status, BudgetPeriodFilterStatus.ready);
    },
  );

  blocTest<BudgetPeriodFilterCubit, BudgetPeriodFilterState>(
    'arranca sin selección cuando el filtro no tenía presupuesto aplicado',
    build: build,
    act: (cubit) async {
      await cubit.start(null);
      await Future<void>.delayed(Duration.zero);
    },
    verify: (cubit) => expect(cubit.state.selectedBudgetId, isNull),
  );

  blocTest<BudgetPeriodFilterCubit, BudgetPeriodFilterState>(
    'select reemplaza la selección anterior (selección única, no acumulable)',
    build: build,
    act: (cubit) async {
      await cubit.start(null);
      cubit.select('a');
      cubit.select('b');
    },
    verify: (cubit) => expect(cubit.state.selectedBudgetId, 'b'),
  );

  blocTest<BudgetPeriodFilterCubit, BudgetPeriodFilterState>(
    'clear vuelve la selección a null',
    build: build,
    act: (cubit) async {
      await cubit.start('a');
      cubit.clear();
    },
    verify: (cubit) => expect(cubit.state.selectedBudgetId, isNull),
  );

  blocTest<BudgetPeriodFilterCubit, BudgetPeriodFilterState>(
    'si el stream de presupuestos falla, el estado pasa a failure',
    build: build,
    setUp: () {
      when(() => watchBudgetPeriodOptions()).thenAnswer(
        (_) => Stream.value(const Left(DatabaseFailure('sin disco'))),
      );
    },
    act: (cubit) async {
      await cubit.start(null);
      await Future<void>.delayed(Duration.zero);
    },
    verify: (cubit) {
      expect(cubit.state.status, BudgetPeriodFilterStatus.failure);
      expect(cubit.state.failure, isA<DatabaseFailure>());
    },
  );

  blocTest<BudgetPeriodFilterCubit, BudgetPeriodFilterState>(
    'reabrir el sheet re-resuelve la ventana en vivo: cancela la '
    'suscripción anterior antes de crear otra',
    build: build,
    act: (cubit) async {
      await cubit.start('a');
      await cubit.start('b');
      await Future<void>.delayed(Duration.zero);
    },
    verify: (cubit) => expect(cubit.state.selectedBudgetId, 'b'),
  );
}
