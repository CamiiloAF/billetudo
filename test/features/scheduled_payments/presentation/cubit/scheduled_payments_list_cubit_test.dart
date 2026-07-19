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
        items: [],
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
}
