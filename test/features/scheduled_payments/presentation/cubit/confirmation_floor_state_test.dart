// The cuota date-picker floor (bugfix: "piso de fecha = inicio de la deuda al
// confirmar una cuota") is enforced by feeding `disabledBefore` on the
// confirmation date field. The value comes from
// `PendingScheduledOccurrence.confirmationMinDate` and is surfaced to the two
// UI paths that own a date picker through their state's `minDate` getter:
//
//   - the standalone "Por confirmar" confirmation sheet (`ConfirmationSheetState`)
//   - "Revisar todas" guided review (`GuidedReviewState`)
//
// (The third path — the PP detail's own confirm — reuses the confirmation sheet,
// so it is the same getter.) The entity-level floor and the repository's
// defensive rejection are covered in the data-layer tests; this file locks the
// presentation forwarding so a cuota can never surface a picker without its
// floor, and a non-cuota never gets a spurious one.
import 'package:billetudo/features/scheduled_payments/domain/entities/pending_scheduled_occurrence.dart';
import 'package:billetudo/features/scheduled_payments/domain/entities/scheduled_payment_occurrence.dart';
import 'package:billetudo/features/scheduled_payments/presentation/cubit/confirmation_sheet_state.dart';
import 'package:billetudo/features/scheduled_payments/presentation/cubit/guided_review_state.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../scheduled_payment_fixtures.dart';

void main() {
  final occurrence = ScheduledPaymentOccurrence(
    id: 'occ-1',
    scheduledPaymentId: 'sp-1',
    occurrenceDate: testInstant,
    status: ScheduledOccurrenceStatus.pending,
    createdAt: testInstant,
    updatedAt: testInstantMillis,
  );

  // A cuota: the template carries a debtId and the debt still records a
  // startDate, so the floor is that startDate.
  final cuotaSource = PendingScheduledOccurrence(
    occurrence: occurrence,
    scheduledPayment: buildScheduledPayment(
      requiresConfirmation: true,
      debtId: 'debt-1',
    ),
    accountName: 'Bancolombia',
    categoryName: 'Cuota crédito',
    debtStartDate: DateTime(2026, 7, 1),
  );

  // An ordinary scheduled payment: no debt, so no floor even if a stray
  // debtStartDate were present (it never should be).
  final ordinarySource = PendingScheduledOccurrence(
    occurrence: occurrence,
    scheduledPayment: buildScheduledPayment(requiresConfirmation: true),
    accountName: 'Bancolombia',
    categoryName: 'Arriendo',
  );

  group('ConfirmationSheetState.minDate', () {
    test('forwards the debt startDate as the floor for a cuota', () {
      final state = ConfirmationSheetState.loaded(cuotaSource);
      expect(state.minDate, DateTime(2026, 7, 1));
    });

    test('is null (no floor) for an ordinary scheduled payment', () {
      final state = ConfirmationSheetState.loaded(ordinarySource);
      expect(state.minDate, isNull);
    });
  });

  group('GuidedReviewState.minDate', () {
    test('forwards the current occurrence floor for a cuota', () {
      const state = GuidedReviewState(status: GuidedReviewStatus.ready);
      final withCuota = GuidedReviewState(
        status: GuidedReviewStatus.ready,
        queue: [cuotaSource],
      );
      // Empty queue → no current occurrence → no floor.
      expect(state.minDate, isNull);
      expect(withCuota.minDate, DateTime(2026, 7, 1));
    });

    test('is null (no floor) for an ordinary scheduled payment', () {
      final state = GuidedReviewState(
        status: GuidedReviewStatus.ready,
        queue: [ordinarySource],
      );
      expect(state.minDate, isNull);
    });
  });
}
