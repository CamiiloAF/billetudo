import 'package:billetudo/core/error/result.dart';
import 'package:billetudo/features/scheduled_payments/domain/entities/pending_scheduled_occurrence.dart';
import 'package:billetudo/features/scheduled_payments/domain/entities/scheduled_payment_occurrence.dart';
import 'package:billetudo/features/scheduled_payments/domain/entities/snooze_outcome.dart';
import 'package:billetudo/features/scheduled_payments/presentation/cubit/confirmation_sheet_cubit.dart';
import 'package:billetudo/features/scheduled_payments/presentation/cubit/confirmation_sheet_state.dart';
import 'package:billetudo/features/transactions/domain/entities/transaction.dart'
    as tx;
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../scheduled_payment_fixtures.dart';
import 'usecase_mocks.dart';

tx.Transaction _buildGeneratedTransaction() => tx.Transaction(
      id: 'tx-1',
      accountId: 'acc-1',
      amountMinor: 20000,
      currency: 'COP',
      type: tx.TransactionType.expense,
      date: testInstant,
      source: tx.TransactionSource.scheduled,
      createdAt: testInstant,
      updatedAt: testInstantMillis,
    );

void main() {
  late MockConfirmScheduledOccurrence confirmOccurrence;
  late MockSkipScheduledOccurrence skipOccurrence;
  late MockSnoozeScheduledOccurrence snoozeOccurrence;

  final occurrence = ScheduledPaymentOccurrence(
    id: 'occ-1',
    scheduledPaymentId: 'sp-1',
    occurrenceDate: testInstant,
    status: ScheduledOccurrenceStatus.pending,
    createdAt: testInstant,
    updatedAt: testInstantMillis,
  );

  final source = PendingScheduledOccurrence(
    occurrence: occurrence,
    scheduledPayment: buildScheduledPayment(requiresConfirmation: true),
    accountName: 'Bancolombia',
    categoryName: 'Arriendo',
  );

  setUpAll(registerScheduledPaymentPresentationFallbacks);

  setUp(() {
    confirmOccurrence = MockConfirmScheduledOccurrence();
    skipOccurrence = MockSkipScheduledOccurrence();
    snoozeOccurrence = MockSnoozeScheduledOccurrence();
  });

  ConfirmationSheetCubit build() => ConfirmationSheetCubit(
      confirmOccurrence, skipOccurrence, snoozeOccurrence);

  group('load (criterion 7)', () {
    blocTest<ConfirmationSheetCubit, ConfirmationSheetState>(
      'prefills date/accountId/amountMinor editable from the template current values',
      build: build,
      act: (cubit) => cubit.load(source),
      verify: (cubit) {
        expect(cubit.state.isReady, isTrue);
        expect(cubit.state.date, occurrence.effectiveDate);
        expect(cubit.state.accountId, 'acc-1');
        expect(cubit.state.amountMinor, 10000);
        expect(cubit.state.categoryName, 'Arriendo');
      },
    );
  });

  group('confirm (criterion 7/8)', () {
    blocTest<ConfirmationSheetCubit, ConfirmationSheetState>(
      'applies only the edited date/account/amount, never rewriting the template',
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
        cubit.load(source);
        cubit.amountChanged(20000);
        await cubit.confirm();
      },
      verify: (cubit) {
        expect(cubit.state.status, ConfirmationSheetStatus.confirmed);
        verify(
          () => confirmOccurrence(
            occurrenceId: 'occ-1',
            date: occurrence.effectiveDate,
            accountId: 'acc-1',
            amountMinor: 20000,
          ),
        ).called(1);
      },
    );

    blocTest<ConfirmationSheetCubit, ConfirmationSheetState>(
      'a non-positive amount is rejected before calling the use case',
      build: build,
      act: (cubit) async {
        cubit.load(source);
        cubit.amountChanged(0);
        await cubit.confirm();
      },
      verify: (cubit) {
        expect(cubit.state.failure, isNotNull);
        verifyNever(
          () => confirmOccurrence(
            occurrenceId: any(named: 'occurrenceId'),
            date: any(named: 'date'),
            accountId: any(named: 'accountId'),
            amountMinor: any(named: 'amountMinor'),
          ),
        );
      },
    );
  });

  group('skip (criterion 9)', () {
    blocTest<ConfirmationSheetCubit, ConfirmationSheetState>(
      'discards the occurrence without generating a transaction',
      setUp: () => when(() => skipOccurrence(any()))
          .thenAnswer((_) async => const Right(unit)),
      build: build,
      act: (cubit) async {
        cubit.load(source);
        await cubit.skip();
      },
      verify: (cubit) {
        expect(cubit.state.status, ConfirmationSheetStatus.skipped);
        verify(() => skipOccurrence('occ-1')).called(1);
      },
    );
  });

  group('snooze (criterion 10)', () {
    blocTest<ConfirmationSheetCubit, ConfirmationSheetState>(
      'moves only this occurrence to the new date',
      setUp: () => when(
        () => snoozeOccurrence(
          scheduledPaymentId: any(named: 'scheduledPaymentId'),
          occurrenceDate: any(named: 'occurrenceDate'),
          newDate: any(named: 'newDate'),
        ),
      ).thenAnswer(
        (_) async => Right(
          SnoozeOutcome(occurrence: occurrence, wasCreated: false),
        ),
      ),
      build: build,
      act: (cubit) async {
        cubit.load(source);
        await cubit.snooze(DateTime(2026, 8, 1));
      },
      verify: (cubit) {
        expect(cubit.state.status, ConfirmationSheetStatus.snoozed);
        verify(
          () => snoozeOccurrence(
            scheduledPaymentId: 'sp-1',
            occurrenceDate: occurrence.occurrenceDate,
            newDate: DateTime(2026, 8, 1),
          ),
        ).called(1);
      },
    );
  });
}
