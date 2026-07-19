import 'package:billetudo/core/error/result.dart';
import 'package:billetudo/features/scheduled_payments/domain/entities/scheduled_payment_summary.dart';
import 'package:billetudo/features/scheduled_payments/presentation/cubit/finished_scheduled_payments_cubit.dart';
import 'package:billetudo/features/scheduled_payments/presentation/cubit/finished_scheduled_payments_state.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../scheduled_payment_fixtures.dart';
import 'usecase_mocks.dart';

void main() {
  late MockGetFinishedScheduledPayments getFinishedScheduledPayments;

  final summary = ScheduledPaymentSummary(
    scheduledPayment: buildScheduledPayment(),
    accountName: 'Bancolombia',
  );

  setUp(() {
    getFinishedScheduledPayments = MockGetFinishedScheduledPayments();
  });

  FinishedScheduledPaymentsCubit build() =>
      FinishedScheduledPaymentsCubit(getFinishedScheduledPayments);

  blocTest<FinishedScheduledPaymentsCubit, FinishedScheduledPaymentsState>(
    'emits the finished templates history ("Terminados")',
    setUp: () => when(() => getFinishedScheduledPayments())
        .thenAnswer((_) => Stream.value(Right([summary]))),
    build: build,
    act: (cubit) => cubit.start(),
    expect: () => [
      const FinishedScheduledPaymentsState(),
      const FinishedScheduledPaymentsState(
        status: FinishedScheduledPaymentsStatus.ready,
      ).copyWith(items: [summary]),
    ],
  );

  blocTest<FinishedScheduledPaymentsCubit, FinishedScheduledPaymentsState>(
    'a stream failure lands in failure status',
    setUp: () => when(() => getFinishedScheduledPayments()).thenAnswer(
      (_) => Stream.value(const Left(DatabaseFailure('boom'))),
    ),
    build: build,
    act: (cubit) => cubit.start(),
    verify: (cubit) {
      expect(cubit.state.status, FinishedScheduledPaymentsStatus.failure);
    },
  );
}
