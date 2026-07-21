import 'package:billetudo/core/error/result.dart';
import 'package:billetudo/features/scheduled_payments/domain/entities/snooze_outcome.dart';
import 'package:billetudo/features/scheduled_payments/presentation/cubit/snooze_sheet_cubit.dart';
import 'package:billetudo/features/scheduled_payments/presentation/cubit/snooze_sheet_state.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../scheduled_payment_fixtures.dart';
import 'usecase_mocks.dart';

/// HU-07: the Posponer sheet's floor is `max(fecha original, hoy)` and the new
/// date must be strictly after it, so the first selectable day is the day
/// after that floor; saving
/// moves only the target occurrence, and it never affects the template's
/// cadence or balance (that lives entirely in the use case; here we only
/// verify the cubit wires it correctly).
void main() {
  late MockSnoozeScheduledOccurrence snoozeOccurrence;

  setUpAll(registerScheduledPaymentPresentationFallbacks);

  setUp(() {
    snoozeOccurrence = MockSnoozeScheduledOccurrence();
  });

  SnoozeSheetCubit build() => SnoozeSheetCubit(snoozeOccurrence);

  group('start', () {
    blocTest<SnoozeSheetCubit, SnoozeSheetState>(
      'first selectable day is the day after the occurrence date when it is '
      'later than today',
      build: build,
      act: (cubit) => cubit.start(
        scheduledPaymentId: 'sp-1',
        occurrenceDate: DateTime(2026, 8, 10),
        today: DateTime(2026, 7, 15),
      ),
      expect: () => [
        SnoozeSheetState(
          minDate: DateTime(2026, 8, 11),
          selectedDate: DateTime(2026, 8, 11),
        ),
      ],
    );

    blocTest<SnoozeSheetCubit, SnoozeSheetState>(
      'first selectable day is tomorrow when the occurrence date is already '
      'in the past (overdue)',
      build: build,
      act: (cubit) => cubit.start(
        scheduledPaymentId: 'sp-1',
        occurrenceDate: DateTime(2026, 7),
        today: DateTime(2026, 7, 15),
      ),
      expect: () => [
        SnoozeSheetState(
          minDate: DateTime(2026, 7, 16),
          selectedDate: DateTime(2026, 7, 16),
        ),
      ],
    );
  });

  blocTest<SnoozeSheetCubit, SnoozeSheetState>(
    'dateSelected updates selectedDate without touching minDate',
    build: build,
    act: (cubit) {
      cubit.start(
        scheduledPaymentId: 'sp-1',
        occurrenceDate: DateTime(2026, 7, 15),
        today: DateTime(2026, 7, 15),
      );
      cubit.dateSelected(DateTime(2026, 7, 20));
    },
    expect: () => [
      SnoozeSheetState(
        minDate: DateTime(2026, 7, 16),
        selectedDate: DateTime(2026, 7, 16),
      ),
      SnoozeSheetState(
        minDate: DateTime(2026, 7, 16),
        selectedDate: DateTime(2026, 7, 20),
      ),
    ],
  );

  blocTest<SnoozeSheetCubit, SnoozeSheetState>(
    'save: on success moves to saved with the returned occurrence',
    setUp: () => when(
      () => snoozeOccurrence(
        scheduledPaymentId: any(named: 'scheduledPaymentId'),
        occurrenceDate: any(named: 'occurrenceDate'),
        newDate: any(named: 'newDate'),
      ),
    ).thenAnswer(
      (_) async => Right(
        SnoozeOutcome(
          occurrence: buildOccurrence(id: 'occ-9'),
          wasCreated: false,
        ),
      ),
    ),
    build: build,
    act: (cubit) async {
      cubit.start(
        scheduledPaymentId: 'sp-1',
        occurrenceDate: DateTime(2026, 7, 15),
        today: DateTime(2026, 7, 15),
      );
      cubit.dateSelected(DateTime(2026, 7, 20));
      await cubit.save();
    },
    verify: (cubit) {
      expect(cubit.state.status, SnoozeSheetStatus.saved);
      expect(cubit.state.saved?.occurrence.id, 'occ-9');
      verify(
        () => snoozeOccurrence(
          scheduledPaymentId: 'sp-1',
          occurrenceDate: DateTime(2026, 7, 15),
          newDate: DateTime(2026, 7, 20),
        ),
      ).called(1);
    },
  );

  blocTest<SnoozeSheetCubit, SnoozeSheetState>(
    'save: on failure moves to failure status and keeps the failure',
    setUp: () => when(
      () => snoozeOccurrence(
        scheduledPaymentId: any(named: 'scheduledPaymentId'),
        occurrenceDate: any(named: 'occurrenceDate'),
        newDate: any(named: 'newDate'),
      ),
    ).thenAnswer((_) async => const Left(DatabaseFailure('boom'))),
    build: build,
    act: (cubit) async {
      cubit.start(
        scheduledPaymentId: 'sp-1',
        occurrenceDate: DateTime(2026, 7, 15),
        today: DateTime(2026, 7, 15),
      );
      await cubit.save();
    },
    verify: (cubit) {
      expect(cubit.state.status, SnoozeSheetStatus.failure);
      expect(cubit.state.failure, isA<DatabaseFailure>());
    },
  );
}
