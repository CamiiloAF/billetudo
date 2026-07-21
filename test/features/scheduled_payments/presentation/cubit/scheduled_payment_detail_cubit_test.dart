import 'package:billetudo/core/error/result.dart';
import 'package:billetudo/features/scheduled_payments/domain/entities/scheduled_payment_detail.dart';
import 'package:billetudo/features/scheduled_payments/domain/usecases/advance_scheduled_occurrence.dart';
import 'package:billetudo/features/scheduled_payments/domain/usecases/discard_unconfirmed_advance_occurrence.dart';
import 'package:billetudo/features/scheduled_payments/presentation/cubit/scheduled_payment_detail_cubit.dart';
import 'package:billetudo/features/scheduled_payments/presentation/cubit/scheduled_payment_detail_state.dart';
import 'package:billetudo/features/transactions/domain/usecases/restore_transaction.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../scheduled_payment_fixtures.dart';
import 'usecase_mocks.dart';

class MockRestoreTransaction extends Mock implements RestoreTransaction {}

class MockAdvanceScheduledOccurrence extends Mock
    implements AdvanceScheduledOccurrence {}

class MockDiscardUnconfirmedAdvanceOccurrence extends Mock
    implements DiscardUnconfirmedAdvanceOccurrence {}

/// HU-05/HU-07: hybrid detail screen — load, error, in-place history
/// pagination (criterion 13), delete flow (criterion 12), and the
/// posponer/deshacer bridge (criterion 10).
void main() {
  late MockGetScheduledPaymentDetail getDetail;
  late MockGetScheduledPaymentHistory getHistory;
  late MockDeleteScheduledPayment deleteScheduledPayment;
  late MockUndoSnoozeScheduledOccurrence undoSnoozeOccurrence;
  late MockRestoreTransaction restoreTransaction;
  late MockAdvanceScheduledOccurrence advanceScheduledOccurrence;
  late MockDiscardUnconfirmedAdvanceOccurrence discardUnconfirmedAdvance;
  late MockUndoSkipScheduledOccurrence undoSkipOccurrence;
  late MockSkipScheduledOccurrence skipOccurrence;

  final detail = ScheduledPaymentDetail(
    scheduledPayment: buildScheduledPayment(),
    accountName: 'Bancolombia',
    historyTotalCount: 5,
  );

  setUpAll(registerScheduledPaymentPresentationFallbacks);

  setUp(() {
    getDetail = MockGetScheduledPaymentDetail();
    getHistory = MockGetScheduledPaymentHistory();
    deleteScheduledPayment = MockDeleteScheduledPayment();
    undoSnoozeOccurrence = MockUndoSnoozeScheduledOccurrence();
    restoreTransaction = MockRestoreTransaction();
    advanceScheduledOccurrence = MockAdvanceScheduledOccurrence();
    discardUnconfirmedAdvance = MockDiscardUnconfirmedAdvanceOccurrence();
    undoSkipOccurrence = MockUndoSkipScheduledOccurrence();
    skipOccurrence = MockSkipScheduledOccurrence();
    when(() => discardUnconfirmedAdvance(any()))
        .thenAnswer((_) async => const Right(unit));
  });

  ScheduledPaymentDetailCubit build() => ScheduledPaymentDetailCubit(
        getDetail,
        getHistory,
        deleteScheduledPayment,
        undoSnoozeOccurrence,
        restoreTransaction,
        advanceScheduledOccurrence,
        discardUnconfirmedAdvance,
        undoSkipOccurrence,
        skipOccurrence,
      );

  blocTest<ScheduledPaymentDetailCubit, ScheduledPaymentDetailState>(
    'start: subscribes and emits the ready detail from the stream',
    setUp: () => when(() => getDetail('sp-1'))
        .thenAnswer((_) => Stream.value(Right(detail))),
    build: build,
    act: (cubit) => cubit.start('sp-1'),
    expect: () => [
      const ScheduledPaymentDetailState(),
      isA<ScheduledPaymentDetailState>()
          .having((s) => s.status, 'status', ScheduledPaymentDetailStatus.ready)
          .having((s) => s.detail, 'detail', detail),
    ],
  );

  blocTest<ScheduledPaymentDetailCubit, ScheduledPaymentDetailState>(
    'start: a stream failure lands in failure status',
    setUp: () => when(() => getDetail('sp-1')).thenAnswer(
      (_) => Stream.value(const Left(DatabaseFailure('boom'))),
    ),
    build: build,
    act: (cubit) => cubit.start('sp-1'),
    verify: (cubit) {
      expect(cubit.state.status, ScheduledPaymentDetailStatus.failure);
      expect(cubit.state.failure, isA<DatabaseFailure>());
    },
  );

  group('loadMoreHistory', () {
    blocTest<ScheduledPaymentDetailCubit, ScheduledPaymentDetailState>(
      'criterion 13: appends the next page in place and marks history as expanded',
      setUp: () {
        when(() => getDetail('sp-1'))
            .thenAnswer((_) => Stream.value(Right(detail)));
        when(
          () => getHistory('sp-1',
              offset: any(named: 'offset'), limit: any(named: 'limit')),
        ).thenAnswer((_) async => const Right([]));
      },
      build: build,
      act: (cubit) async {
        await cubit.start('sp-1');
        await Future<void>.delayed(Duration.zero);
        await cubit.loadMoreHistory();
      },
      verify: (cubit) {
        expect(cubit.state.historyExpanded, isTrue);
        expect(cubit.state.loadingMoreHistory, isFalse);
        verify(
          () => getHistory('sp-1', offset: 0, limit: 10),
        ).called(1);
      },
    );

    blocTest<ScheduledPaymentDetailCubit, ScheduledPaymentDetailState>(
      'does nothing when there is no more history to load',
      setUp: () => when(() => getDetail('sp-1')).thenAnswer(
        (_) => Stream.value(
          Right(
            ScheduledPaymentDetail(
              scheduledPayment: buildScheduledPayment(),
              accountName: 'Bancolombia',
              historyTotalCount: 0,
            ),
          ),
        ),
      ),
      build: build,
      act: (cubit) async {
        await cubit.start('sp-1');
        await Future<void>.delayed(Duration.zero);
        await cubit.loadMoreHistory();
      },
      verify: (_) {
        verifyNever(
          () => getHistory(
            any(),
            offset: any(named: 'offset'),
            limit: any(named: 'limit'),
          ),
        );
      },
    );
  });

  group('delete flow (criterion 12)', () {
    blocTest<ScheduledPaymentDetailCubit, ScheduledPaymentDetailState>(
      'requestDelete/cancelDelete toggle the confirmation prompt',
      build: build,
      act: (cubit) {
        cubit.requestDelete();
        cubit.cancelDelete();
      },
      expect: () => [
        const ScheduledPaymentDetailState(deletePrompt: true),
        const ScheduledPaymentDetailState(),
      ],
    );

    blocTest<ScheduledPaymentDetailCubit, ScheduledPaymentDetailState>(
      'confirmDelete: on success moves to closed and clears the prompt',
      setUp: () {
        when(() => getDetail('sp-1'))
            .thenAnswer((_) => Stream.value(Right(detail)));
        when(() => deleteScheduledPayment('sp-1'))
            .thenAnswer((_) async => const Right(unit));
      },
      build: build,
      act: (cubit) async {
        await cubit.start('sp-1');
        cubit.requestDelete();
        await cubit.confirmDelete();
      },
      verify: (cubit) {
        expect(cubit.state.status, ScheduledPaymentDetailStatus.closed);
        expect(cubit.state.deletePrompt, isFalse);
      },
    );

    blocTest<ScheduledPaymentDetailCubit, ScheduledPaymentDetailState>(
      'confirmDelete: on failure moves to failure status and clears the prompt',
      setUp: () {
        when(() => getDetail('sp-1'))
            .thenAnswer((_) => Stream.value(Right(detail)));
        when(() => deleteScheduledPayment('sp-1'))
            .thenAnswer((_) async => const Left(DatabaseFailure('boom')));
      },
      build: build,
      act: (cubit) async {
        await cubit.start('sp-1');
        cubit.requestDelete();
        await cubit.confirmDelete();
      },
      verify: (cubit) {
        expect(cubit.state.status, ScheduledPaymentDetailStatus.failure);
        expect(cubit.state.deletePrompt, isFalse);
      },
    );
  });

  group('snooze bridge (criterion 10)', () {
    blocTest<ScheduledPaymentDetailCubit, ScheduledPaymentDetailState>(
      'notifySnoozed carries the pre-snooze state for the Snackbar undo',
      build: build,
      act: (cubit) => cubit.notifySnoozed('occ-1', wasCreated: true),
      expect: () => [
        const ScheduledPaymentDetailState(
          pendingUndoSnoozeOccurrenceId: 'occ-1',
          pendingUndoSnoozeWasCreated: true,
        ),
      ],
    );

    blocTest<ScheduledPaymentDetailCubit, ScheduledPaymentDetailState>(
      'undoSnooze of a materialized occurrence deletes it (wasCreated: true)',
      setUp: () => when(
        () => undoSnoozeOccurrence(
          'occ-1',
          wasCreated: any(named: 'wasCreated'),
          previousSnoozedToDate: any(named: 'previousSnoozedToDate'),
        ),
      ).thenAnswer((_) async => const Right(unit)),
      build: build,
      act: (cubit) async {
        // Detail snoozes the not-yet-due next occurrence, materializing it.
        cubit.notifySnoozed('occ-1', wasCreated: true);
        await cubit.undoSnooze();
      },
      verify: (cubit) {
        expect(cubit.state.pendingUndoSnoozeOccurrenceId, isNull);
        verify(
          () => undoSnoozeOccurrence('occ-1', wasCreated: true),
        ).called(1);
      },
    );

    blocTest<ScheduledPaymentDetailCubit, ScheduledPaymentDetailState>(
      'undoSnooze of a re-snooze restores the previous date, one step',
      setUp: () => when(
        () => undoSnoozeOccurrence(
          'occ-1',
          wasCreated: any(named: 'wasCreated'),
          previousSnoozedToDate: any(named: 'previousSnoozedToDate'),
        ),
      ).thenAnswer((_) async => const Right(unit)),
      build: build,
      act: (cubit) async {
        cubit.notifySnoozed(
          'occ-1',
          wasCreated: false,
          previousSnoozedToDate: DateTime(2026, 3, 30),
        );
        await cubit.undoSnooze();
      },
      verify: (cubit) {
        expect(cubit.state.pendingUndoSnoozeOccurrenceId, isNull);
        verify(
          () => undoSnoozeOccurrence(
            'occ-1',
            wasCreated: false,
            previousSnoozedToDate: DateTime(2026, 3, 30),
          ),
        ).called(1);
      },
    );

    blocTest<ScheduledPaymentDetailCubit, ScheduledPaymentDetailState>(
      'dismissUndoSnooze clears the pending id without calling the use case',
      build: build,
      act: (cubit) {
        cubit.notifySnoozed('occ-1', wasCreated: true);
        cubit.dismissUndoSnooze();
      },
      verify: (_) {
        verifyNever(
          () => undoSnoozeOccurrence(
            any(),
            wasCreated: any(named: 'wasCreated'),
          ),
        );
      },
    );
  });

  group('recuperar omitido y deshacer (Fase 2)', () {
    blocTest<ScheduledPaymentDetailCubit, ScheduledPaymentDetailState>(
      'recoverSkipped: en éxito ofrece deshacer con el id de la ocurrencia',
      setUp: () => when(() => undoSkipOccurrence('occ-1'))
          .thenAnswer((_) async => const Right(unit)),
      build: build,
      act: (cubit) => cubit.recoverSkipped('occ-1'),
      verify: (cubit) {
        expect(cubit.state.pendingUndoRecoverOccurrenceId, 'occ-1');
        verify(() => undoSkipOccurrence('occ-1')).called(1);
      },
    );

    blocTest<ScheduledPaymentDetailCubit, ScheduledPaymentDetailState>(
      'recoverSkipped: si falla no ofrece deshacer (silencioso)',
      setUp: () => when(() => undoSkipOccurrence('occ-1'))
          .thenAnswer((_) async => const Left(DatabaseFailure('boom'))),
      build: build,
      act: (cubit) => cubit.recoverSkipped('occ-1'),
      verify: (cubit) {
        expect(cubit.state.pendingUndoRecoverOccurrenceId, isNull);
      },
    );

    blocTest<ScheduledPaymentDetailCubit, ScheduledPaymentDetailState>(
      'undoRecover: re-omite la ocurrencia y limpia el pendiente',
      setUp: () {
        when(() => undoSkipOccurrence('occ-1'))
            .thenAnswer((_) async => const Right(unit));
        when(() => skipOccurrence('occ-1'))
            .thenAnswer((_) async => const Right(unit));
      },
      build: build,
      act: (cubit) async {
        await cubit.recoverSkipped('occ-1');
        await cubit.undoRecover();
      },
      verify: (cubit) {
        expect(cubit.state.pendingUndoRecoverOccurrenceId, isNull);
        verify(() => skipOccurrence('occ-1')).called(1);
      },
    );

    blocTest<ScheduledPaymentDetailCubit, ScheduledPaymentDetailState>(
      'dismissUndoRecover limpia el pendiente sin re-omitir',
      setUp: () => when(() => undoSkipOccurrence('occ-1'))
          .thenAnswer((_) async => const Right(unit)),
      build: build,
      act: (cubit) async {
        await cubit.recoverSkipped('occ-1');
        cubit.dismissUndoRecover();
      },
      verify: (cubit) {
        expect(cubit.state.pendingUndoRecoverOccurrenceId, isNull);
        verifyNever(() => skipOccurrence(any()));
      },
    );
  });

  group('borrar y deshacer desde el historial (HU-05)', () {
    blocTest<ScheduledPaymentDetailCubit, ScheduledPaymentDetailState>(
      'notifyExternalDelete ofrece deshacer con el id de la transacción',
      build: build,
      act: (cubit) => cubit.notifyExternalDelete('tx-1'),
      expect: () => [
        const ScheduledPaymentDetailState(
          pendingUndoDeleteTransactionId: 'tx-1',
        ),
      ],
      verify: (_) => verifyNever(() => restoreTransaction(any())),
    );

    blocTest<ScheduledPaymentDetailCubit, ScheduledPaymentDetailState>(
      'undoDelete restaura la transacción y limpia el pendiente',
      setUp: () => when(() => restoreTransaction('tx-1'))
          .thenAnswer((_) async => const Right(unit)),
      build: build,
      act: (cubit) async {
        cubit.notifyExternalDelete('tx-1');
        await cubit.undoDelete();
      },
      verify: (cubit) {
        expect(cubit.state.pendingUndoDeleteTransactionId, isNull);
        verify(() => restoreTransaction('tx-1')).called(1);
      },
    );

    blocTest<ScheduledPaymentDetailCubit, ScheduledPaymentDetailState>(
      'dismissUndoDelete limpia el pendiente sin restaurar',
      build: build,
      act: (cubit) {
        cubit.notifyExternalDelete('tx-1');
        cubit.dismissUndoDelete();
      },
      verify: (cubit) {
        expect(cubit.state.pendingUndoDeleteTransactionId, isNull);
        verifyNever(() => restoreTransaction(any()));
      },
    );

    blocTest<ScheduledPaymentDetailCubit, ScheduledPaymentDetailState>(
      'undoDelete sin pendiente no llama al caso de uso',
      build: build,
      act: (cubit) => cubit.undoDelete(),
      verify: (_) => verifyNever(() => restoreTransaction(any())),
    );
  });

  group(
      'confirmNow / dismissConfirmNow (HU-05 "Confirmar ahora", '
      'docs/bugfixes.md point 1)', () {
    blocTest<ScheduledPaymentDetailCubit, ScheduledPaymentDetailState>(
      'éxito: emite confirmingNow y luego la ocurrencia materializada',
      setUp: () {
        when(() => getDetail('sp-1'))
            .thenAnswer((_) => Stream.value(Right(detail)));
        when(() => advanceScheduledOccurrence(scheduledPaymentId: 'sp-1'))
            .thenAnswer((_) async => Right(buildPendingOccurrence()));
      },
      build: build,
      act: (cubit) async {
        await cubit.start('sp-1');
        await Future<void>.delayed(Duration.zero);
        await cubit.confirmNow();
      },
      verify: (cubit) {
        expect(cubit.state.confirmingNow, isFalse);
        expect(cubit.state.confirmNowOccurrence, buildPendingOccurrence());
        verify(() => advanceScheduledOccurrence(scheduledPaymentId: 'sp-1'))
            .called(1);
      },
    );

    blocTest<ScheduledPaymentDetailCubit, ScheduledPaymentDetailState>(
      'falla: limpia confirmingNow y guarda la falla, sin ocurrencia',
      setUp: () {
        when(() => getDetail('sp-1'))
            .thenAnswer((_) => Stream.value(Right(detail)));
        when(() => advanceScheduledOccurrence(scheduledPaymentId: 'sp-1'))
            .thenAnswer(
          (_) async => const Left(
            ValidationFailure('only an automatic-mode template can be advanced'),
          ),
        );
      },
      build: build,
      act: (cubit) async {
        await cubit.start('sp-1');
        await Future<void>.delayed(Duration.zero);
        await cubit.confirmNow();
      },
      verify: (cubit) {
        expect(cubit.state.confirmingNow, isFalse);
        expect(cubit.state.confirmNowOccurrence, isNull);
        expect(cubit.state.failure, isA<ValidationFailure>());
      },
    );

    blocTest<ScheduledPaymentDetailCubit, ScheduledPaymentDetailState>(
      'una segunda llamada mientras confirmingNow está en curso no reentra',
      setUp: () {
        when(() => getDetail('sp-1'))
            .thenAnswer((_) => Stream.value(Right(detail)));
        when(() => advanceScheduledOccurrence(scheduledPaymentId: 'sp-1'))
            .thenAnswer((_) async {
          await Future<void>.delayed(const Duration(milliseconds: 10));
          return Right(buildPendingOccurrence());
        });
      },
      build: build,
      act: (cubit) async {
        await cubit.start('sp-1');
        await Future<void>.delayed(Duration.zero);
        final first = cubit.confirmNow();
        final second = cubit.confirmNow();
        await Future.wait([first, second]);
      },
      verify: (_) {
        verify(() => advanceScheduledOccurrence(scheduledPaymentId: 'sp-1'))
            .called(1);
      },
    );

    blocTest<ScheduledPaymentDetailCubit, ScheduledPaymentDetailState>(
      'dismissConfirmNow limpia el trigger y descarta la ocurrencia '
      'especulativa (por si el usuario cerró sin confirmar)',
      setUp: () {
        when(() => getDetail('sp-1'))
            .thenAnswer((_) => Stream.value(Right(detail)));
        when(() => advanceScheduledOccurrence(scheduledPaymentId: 'sp-1'))
            .thenAnswer(
          (_) async =>
              Right(buildPendingOccurrence(occurrence: buildOccurrence(id: 'occ-9'))),
        );
      },
      build: build,
      act: (cubit) async {
        await cubit.start('sp-1');
        await Future<void>.delayed(Duration.zero);
        await cubit.confirmNow();
        await cubit.dismissConfirmNow();
      },
      verify: (cubit) {
        expect(cubit.state.confirmNowOccurrence, isNull);
        verify(() => discardUnconfirmedAdvance('occ-9')).called(1);
      },
    );
  });
}
