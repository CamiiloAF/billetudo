import 'package:billetudo/core/error/result.dart';
import 'package:billetudo/features/scheduled_payments/domain/entities/pending_scheduled_occurrence.dart';
import 'package:billetudo/features/scheduled_payments/domain/entities/scheduled_payment_occurrence.dart';
import 'package:billetudo/features/scheduled_payments/presentation/cubit/guided_review_cubit.dart';
import 'package:billetudo/features/scheduled_payments/presentation/cubit/guided_review_state.dart';
import 'package:billetudo/features/transactions/domain/entities/transaction.dart' as tx;
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../scheduled_payment_fixtures.dart';
import 'usecase_mocks.dart';

tx.Transaction _buildGeneratedTransaction() => tx.Transaction(
      id: 'tx-1',
      accountId: 'acc-1',
      amountMinor: 10000,
      currency: 'COP',
      type: tx.TransactionType.expense,
      date: testInstant,
      source: tx.TransactionSource.scheduled,
      createdAt: testInstant,
      updatedAt: testInstantMillis,
    );

PendingScheduledOccurrence _buildPending({
  required String occurrenceId,
  required String scheduledPaymentId,
}) =>
    PendingScheduledOccurrence(
      occurrence: ScheduledPaymentOccurrence(
        id: occurrenceId,
        scheduledPaymentId: scheduledPaymentId,
        occurrenceDate: testInstant,
        status: ScheduledOccurrenceStatus.pending,
        createdAt: testInstant,
        updatedAt: testInstantMillis,
      ),
      scheduledPayment: buildScheduledPayment(
        id: scheduledPaymentId,
        requiresConfirmation: true,
      ),
      accountName: 'Bancolombia',
      categoryName: 'Arriendo',
    );

void main() {
  late MockConfirmScheduledOccurrence confirmOccurrence;
  late MockSkipScheduledOccurrence skipOccurrence;
  late MockSnoozeScheduledOccurrence snoozeOccurrence;

  final firstPending =
      _buildPending(occurrenceId: 'occ-1', scheduledPaymentId: 'sp-1');
  final secondPending =
      _buildPending(occurrenceId: 'occ-2', scheduledPaymentId: 'sp-2');

  setUpAll(registerScheduledPaymentPresentationFallbacks);

  setUp(() {
    confirmOccurrence = MockConfirmScheduledOccurrence();
    skipOccurrence = MockSkipScheduledOccurrence();
    snoozeOccurrence = MockSnoozeScheduledOccurrence();
  });

  GuidedReviewCubit build() =>
      GuidedReviewCubit(confirmOccurrence, skipOccurrence, snoozeOccurrence);

  group('start (criterion 7: guided review is not an apply-all shortcut)',
      () {
    blocTest<GuidedReviewCubit, GuidedReviewState>(
      'loads the first occurrence pre-filled and editable, exactly like the standalone sheet',
      build: build,
      act: (cubit) => cubit.start([firstPending, secondPending]),
      verify: (cubit) {
        expect(cubit.state.isReady, isTrue);
        expect(cubit.state.total, 2);
        expect(cubit.state.position, 1);
        expect(cubit.state.date, firstPending.occurrence.effectiveDate);
        expect(cubit.state.accountId, 'acc-1');
        expect(cubit.state.amountMinor, 10000);
      },
    );

    blocTest<GuidedReviewCubit, GuidedReviewState>(
      'an empty pending list finishes immediately without touching any use case',
      build: build,
      act: (cubit) => cubit.start(const []),
      verify: (cubit) {
        expect(cubit.state.isFinished, isTrue);
        verifyZeroInteractions(confirmOccurrence);
      },
    );
  });

  group('confirmCurrent (criterion 7/8)', () {
    blocTest<GuidedReviewCubit, GuidedReviewState>(
      'never applies without going through the same explicit confirm call as the standalone sheet, and advances to the next occurrence',
      setUp: () => when(
        () => confirmOccurrence(
          occurrenceId: any(named: 'occurrenceId'),
          date: any(named: 'date'),
          accountId: any(named: 'accountId'),
          amountMinor: any(named: 'amountMinor'),
        ),
      ).thenAnswer((_) async => Right(_buildGeneratedTransaction())),
      build: build,
      act: (cubit) async {
        cubit.start([firstPending, secondPending]);
        await cubit.confirmCurrent();
      },
      verify: (cubit) {
        verify(
          () => confirmOccurrence(
            occurrenceId: 'occ-1',
            date: firstPending.occurrence.effectiveDate,
            accountId: 'acc-1',
            amountMinor: 10000,
          ),
        ).called(1);
        expect(cubit.state.position, 2);
        expect(cubit.state.resolvedCount, 1);
        expect(cubit.state.accountId, 'acc-1');
      },
    );

    blocTest<GuidedReviewCubit, GuidedReviewState>(
      'a non-positive edited amount is rejected before calling the use case',
      build: build,
      act: (cubit) async {
        cubit.start([firstPending]);
        cubit.amountChanged(0);
        await cubit.confirmCurrent();
      },
      verify: (cubit) {
        expect(cubit.state.failure, isNotNull);
        expect(cubit.state.position, 1);
        verifyZeroInteractions(confirmOccurrence);
      },
    );

    blocTest<GuidedReviewCubit, GuidedReviewState>(
      'confirming the last occurrence finishes the review',
      setUp: () => when(
        () => confirmOccurrence(
          occurrenceId: any(named: 'occurrenceId'),
          date: any(named: 'date'),
          accountId: any(named: 'accountId'),
          amountMinor: any(named: 'amountMinor'),
        ),
      ).thenAnswer((_) async => Right(_buildGeneratedTransaction())),
      build: build,
      act: (cubit) async {
        cubit.start([firstPending]);
        await cubit.confirmCurrent();
      },
      verify: (cubit) {
        expect(cubit.state.isFinished, isTrue);
        expect(cubit.state.resolvedCount, 1);
      },
    );
  });

  group('skipCurrent (criterion 9)', () {
    blocTest<GuidedReviewCubit, GuidedReviewState>(
      'discards the current occurrence without generating a transaction and moves on',
      setUp: () => when(() => skipOccurrence('occ-1'))
          .thenAnswer((_) async => const Right(unit)),
      build: build,
      act: (cubit) async {
        cubit.start([firstPending, secondPending]);
        await cubit.skipCurrent();
      },
      verify: (cubit) {
        verify(() => skipOccurrence('occ-1')).called(1);
        verifyZeroInteractions(confirmOccurrence);
        expect(cubit.state.position, 2);
        expect(cubit.state.accountId, 'acc-1');
      },
    );
  });

  group('snoozeCurrent (criterion 10)', () {
    blocTest<GuidedReviewCubit, GuidedReviewState>(
      'moves only the current occurrence without affecting the template cadence, then advances',
      setUp: () => when(
        () => snoozeOccurrence(
          scheduledPaymentId: any(named: 'scheduledPaymentId'),
          occurrenceDate: any(named: 'occurrenceDate'),
          newDate: any(named: 'newDate'),
        ),
      ).thenAnswer((_) async => Right(firstPending.occurrence)),
      build: build,
      act: (cubit) async {
        cubit.start([firstPending, secondPending]);
        await cubit.snoozeCurrent(DateTime(2026, 8, 1));
      },
      verify: (cubit) {
        verify(
          () => snoozeOccurrence(
            scheduledPaymentId: 'sp-1',
            occurrenceDate: firstPending.occurrence.occurrenceDate,
            newDate: DateTime(2026, 8, 1),
          ),
        ).called(1);
        verifyZeroInteractions(confirmOccurrence);
        expect(cubit.state.position, 2);
      },
    );
  });
}
