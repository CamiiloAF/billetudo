import 'dart:async';

import 'package:billetudo/core/error/result.dart';
import 'package:billetudo/features/scheduled_payments/domain/entities/scheduled_payment_summary.dart';
import 'package:billetudo/features/scheduled_payments/presentation/cubit/scheduled_payments_list_cubit.dart';
import 'package:billetudo/features/scheduled_payments/presentation/cubit/scheduled_payments_list_state.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../scheduled_payment_fixtures.dart';
import 'usecase_mocks.dart';

void main() {
  late MockGetScheduledPayments getScheduledPayments;
  late MockGenerateDueScheduledPayments generateDueScheduledPayments;
  late MockGetFinishedScheduledPayments getFinishedScheduledPayments;

  final summary = ScheduledPaymentSummary(
    scheduledPayment: buildScheduledPayment(),
    accountName: 'Bancolombia',
  );

  setUpAll(registerScheduledPaymentPresentationFallbacks);

  setUp(() {
    getScheduledPayments = MockGetScheduledPayments();
    generateDueScheduledPayments = MockGenerateDueScheduledPayments();
    getFinishedScheduledPayments = MockGetFinishedScheduledPayments();
    when(() => generateDueScheduledPayments(now: any(named: 'now')))
        .thenAnswer((_) async => const Right(unit));
    when(() => getFinishedScheduledPayments())
        .thenAnswer((_) => Stream.value(const Right([])));
  });

  ScheduledPaymentsListCubit build() => ScheduledPaymentsListCubit(
        getScheduledPayments,
        generateDueScheduledPayments,
        getFinishedScheduledPayments,
      );

  blocTest<ScheduledPaymentsListCubit, ScheduledPaymentsListState>(
    'HU-02: runs the catch-up before subscribing, then emits the list (HU-04)',
    setUp: () => when(() => getScheduledPayments())
        .thenAnswer((_) => Stream.value(Right([summary]))),
    build: build,
    act: (cubit) => cubit.start(),
    expect: () => [
      const ScheduledPaymentsListState(),
      const ScheduledPaymentsListState(
        status: ScheduledPaymentsListStatus.ready,
      ).copyWith(items: [summary]),
      const ScheduledPaymentsListState(
        status: ScheduledPaymentsListStatus.ready,
        finishedStatus: ScheduledPaymentsListStatus.ready,
      ).copyWith(items: [summary]),
    ],
    verify: (_) {
      verify(() => generateDueScheduledPayments(now: any(named: 'now')))
          .called(1);
    },
  );

  blocTest<ScheduledPaymentsListCubit, ScheduledPaymentsListState>(
    'criterion 11: "Activos · N" counts every active template once, pending or not',
    setUp: () => when(() => getScheduledPayments()).thenAnswer(
      (_) => Stream.value(
        Right([
          summary,
          ScheduledPaymentSummary(
            scheduledPayment: buildScheduledPayment(id: 'sp-2'),
            accountName: 'Nequi',
            pendingOccurrenceCount: 3,
          ),
        ]),
      ),
    ),
    build: build,
    act: (cubit) => cubit.start(),
    verify: (cubit) {
      expect(cubit.state.activeCount, 2);
    },
  );

  blocTest<ScheduledPaymentsListCubit, ScheduledPaymentsListState>(
    'a stream failure lands in failure status',
    setUp: () => when(() => getScheduledPayments()).thenAnswer(
      (_) => Stream.value(const Left(DatabaseFailure('boom'))),
    ),
    build: build,
    act: (cubit) => cubit.start(),
    verify: (cubit) {
      expect(cubit.state.status, ScheduledPaymentsListStatus.failure);
    },
  );

  final finishedController =
      StreamController<Result<List<ScheduledPaymentSummary>>>.broadcast();

  final finished = ScheduledPaymentSummary(
    scheduledPayment: buildScheduledPayment(id: 'sp-finished'),
    accountName: 'Bancolombia',
    lastPaymentDate: DateTime(2026, 3, 15),
  );

  blocTest<ScheduledPaymentsListCubit, ScheduledPaymentsListState>(
    'el chip de Terminados filtra en sitio: cambia el filtro, no la lista '
    'de activos',
    setUp: () {
      when(() => getScheduledPayments())
          .thenAnswer((_) => Stream.value(Right([summary])));
      when(() => getFinishedScheduledPayments())
          .thenAnswer((_) => Stream.value(Right([finished])));
    },
    build: build,
    act: (cubit) async {
      await cubit.start();
      await pumpEventQueue();
      cubit.showFilter(ScheduledPaymentsFilter.finished);
    },
    verify: (cubit) {
      expect(cubit.state.showsFinished, isTrue);
      expect(cubit.state.finishedCount, 1);
      expect(cubit.state.items, [summary]);
    },
  );

  blocTest<ScheduledPaymentsListCubit, ScheduledPaymentsListState>(
    'sin terminadas no se puede entrar al filtro (el chip ni se dibuja)',
    setUp: () => when(() => getScheduledPayments())
        .thenAnswer((_) => Stream.value(Right([summary]))),
    build: build,
    act: (cubit) async {
      await cubit.start();
      await pumpEventQueue();
      cubit.showFilter(ScheduledPaymentsFilter.finished);
    },
    verify: (cubit) {
      expect(cubit.state.showsFinished, isFalse);
    },
  );

  blocTest<ScheduledPaymentsListCubit, ScheduledPaymentsListState>(
    'si la última terminada desaparece estando dentro del filtro, la lista '
    'cae a Activos',
    setUp: () {
      when(() => getScheduledPayments())
          .thenAnswer((_) => Stream.value(Right([summary])));
      when(() => getFinishedScheduledPayments())
          .thenAnswer((_) => finishedController.stream);
    },
    build: build,
    act: (cubit) async {
      await cubit.start();
      finishedController.add(Right([finished]));
      await pumpEventQueue();
      cubit.showFilter(ScheduledPaymentsFilter.finished);
      finishedController.add(const Right(<ScheduledPaymentSummary>[]));
      await pumpEventQueue();
    },
    tearDown: finishedController.close,
    verify: (cubit) {
      expect(cubit.state.finishedCount, 0);
      expect(cubit.state.showsFinished, isFalse);
    },
  );

  blocTest<ScheduledPaymentsListCubit, ScheduledPaymentsListState>(
    'un fallo del stream de terminadas solo marca su propio estado',
    setUp: () {
      when(() => getScheduledPayments())
          .thenAnswer((_) => Stream.value(Right([summary])));
      when(() => getFinishedScheduledPayments()).thenAnswer(
        (_) => Stream.value(const Left(DatabaseFailure('boom'))),
      );
    },
    build: build,
    act: (cubit) => cubit.start(),
    verify: (cubit) {
      expect(cubit.state.finishedStatus, ScheduledPaymentsListStatus.failure);
      expect(cubit.state.status, ScheduledPaymentsListStatus.ready);
    },
  );
}
