import 'package:billetudo/core/error/result.dart';
import 'package:billetudo/features/scheduled_payments/domain/entities/pending_scheduled_occurrence.dart';
import 'package:billetudo/features/scheduled_payments/domain/entities/scheduled_payment_occurrence.dart';
import 'package:billetudo/features/scheduled_payments/presentation/cubit/pending_occurrences_cubit.dart';
import 'package:billetudo/features/scheduled_payments/presentation/cubit/pending_occurrences_state.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../scheduled_payment_fixtures.dart';
import 'usecase_mocks.dart';

void main() {
  late MockGetPendingOccurrences getPendingOccurrences;
  late MockUndoSkipScheduledOccurrence undoSkipOccurrence;
  late MockUndoSnoozeScheduledOccurrence undoSnoozeOccurrence;

  final occurrence = ScheduledPaymentOccurrence(
    id: 'occ-1',
    scheduledPaymentId: 'sp-1',
    occurrenceDate: testInstant,
    status: ScheduledOccurrenceStatus.pending,
    createdAt: testInstant,
    updatedAt: testInstantMillis,
  );

  final pending = PendingScheduledOccurrence(
    occurrence: occurrence,
    scheduledPayment: buildScheduledPayment(requiresConfirmation: true),
    accountName: 'Bancolombia',
  );

  setUpAll(registerScheduledPaymentPresentationFallbacks);

  setUp(() {
    getPendingOccurrences = MockGetPendingOccurrences();
    undoSkipOccurrence = MockUndoSkipScheduledOccurrence();
    undoSnoozeOccurrence = MockUndoSnoozeScheduledOccurrence();
  });

  PendingOccurrencesCubit build() => PendingOccurrencesCubit(
        getPendingOccurrences,
        undoSkipOccurrence,
        undoSnoozeOccurrence,
      );

  blocTest<PendingOccurrencesCubit, PendingOccurrencesState>(
    'HU-03/04: emits every pending occurrence ordered by the stream',
    setUp: () => when(() => getPendingOccurrences())
        .thenAnswer((_) => Stream.value(Right([pending]))),
    build: build,
    act: (cubit) => cubit.start(),
    verify: (cubit) {
      expect(cubit.state.status, PendingOccurrencesStatus.ready);
      expect(cubit.state.items, [pending]);
    },
  );

  group('undo (criterion 9/10)', () {
    blocTest<PendingOccurrencesCubit, PendingOccurrencesState>(
      'notifySkipped offers Deshacer, undo() calls UndoSkipScheduledOccurrence',
      setUp: () => when(() => undoSkipOccurrence(any()))
          .thenAnswer((_) async => const Right(unit)),
      build: build,
      act: (cubit) async {
        cubit.notifySkipped('occ-1');
        await cubit.undo();
      },
      expect: () => [
        const PendingOccurrencesState(
          pendingUndo:
              PendingOccurrenceUndo(occurrenceId: 'occ-1', isSnooze: false),
        ),
        const PendingOccurrencesState(),
      ],
      verify: (_) {
        verify(() => undoSkipOccurrence('occ-1')).called(1);
        verifyNever(
          () => undoSnoozeOccurrence(
            any(),
            wasCreated: any(named: 'wasCreated'),
          ),
        );
      },
    );

    blocTest<PendingOccurrencesCubit, PendingOccurrencesState>(
      'notifySnoozed offers Deshacer, undo() calls UndoSnoozeScheduledOccurrence',
      setUp: () => when(
        () => undoSnoozeOccurrence(
          any(),
          wasCreated: any(named: 'wasCreated'),
          previousSnoozedToDate: any(named: 'previousSnoozedToDate'),
        ),
      ).thenAnswer((_) async => const Right(unit)),
      build: build,
      act: (cubit) async {
        cubit.notifySnoozed('occ-1');
        await cubit.undo();
      },
      verify: (_) {
        // "Por confirmar" only snoozes already-materialized rows, so undo
        // always reverses one step with wasCreated: false.
        verify(
          () => undoSnoozeOccurrence('occ-1', wasCreated: false),
        ).called(1);
        verifyNever(() => undoSkipOccurrence(any()));
      },
    );

    blocTest<PendingOccurrencesCubit, PendingOccurrencesState>(
      'dismissUndo clears the affordance without calling any use case',
      build: build,
      act: (cubit) {
        cubit.notifySkipped('occ-1');
        cubit.dismissUndo();
      },
      verify: (cubit) {
        expect(cubit.state.pendingUndo, isNull);
        verifyNever(() => undoSkipOccurrence(any()));
      },
    );
  });
}
