import 'package:billetudo/core/error/result.dart';
import 'package:billetudo/features/scheduled_payments/domain/entities/scheduled_payment_occurrence.dart';
import 'package:billetudo/features/scheduled_payments/domain/entities/snooze_outcome.dart';
import 'package:billetudo/features/scheduled_payments/domain/usecases/snooze_scheduled_occurrence.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'scheduled_payment_repository_mock.dart';

void main() {
  late MockScheduledPaymentRepository repository;
  late SnoozeScheduledOccurrence snooze;

  ScheduledPaymentOccurrence buildOccurrence() => ScheduledPaymentOccurrence(
        id: 'occ-1',
        scheduledPaymentId: 'sp-1',
        occurrenceDate: DateTime(2026, 7, 10),
        status: ScheduledOccurrenceStatus.snoozed,
        snoozedToDate: DateTime(2026, 7, 20),
        createdAt: DateTime(2026, 7, 10),
        updatedAt: 0,
      );

  setUp(() {
    repository = MockScheduledPaymentRepository();
    snooze = SnoozeScheduledOccurrence(repository);
    when(
      () => repository.snoozeOccurrence(
        scheduledPaymentId: any(named: 'scheduledPaymentId'),
        occurrenceDate: any(named: 'occurrenceDate'),
        newDate: any(named: 'newDate'),
      ),
    ).thenAnswer(
      (_) async => Right(
        SnoozeOutcome(occurrence: buildOccurrence(), wasCreated: false),
      ),
    );
  });

  test(
      'criterio 10: el piso es max(fecha original, hoy) — rechaza una fecha '
      'anterior a la original cuando ya es hoy o después', () async {
    final result = await snooze(
      scheduledPaymentId: 'sp-1',
      occurrenceDate: DateTime(2026, 7, 10),
      newDate: DateTime(2026, 7, 5),
      today: DateTime(2026, 7, 12),
    );

    expect(result.isLeft(), isTrue);
    verifyNever(
      () => repository.snoozeOccurrence(
        scheduledPaymentId: any(named: 'scheduledPaymentId'),
        occurrenceDate: any(named: 'occurrenceDate'),
        newDate: any(named: 'newDate'),
      ),
    );
  });

  test('rechaza una fecha anterior a hoy aunque sea posterior a la original',
      () async {
    final result = await snooze(
      scheduledPaymentId: 'sp-1',
      occurrenceDate: DateTime(2026, 7, 1),
      newDate: DateTime(2026, 7, 5),
      today: DateTime(2026, 7, 12),
    );

    expect(result.isLeft(), isTrue);
  });

  test('acepta hoy mismo cuando la ocurrencia ya estaba vencida', () async {
    final result = await snooze(
      scheduledPaymentId: 'sp-1',
      occurrenceDate: DateTime(2026, 7, 1),
      newDate: DateTime(2026, 7, 12),
      today: DateTime(2026, 7, 12),
    );

    expect(result.isRight(), isTrue);
    verify(
      () => repository.snoozeOccurrence(
        scheduledPaymentId: 'sp-1',
        occurrenceDate: DateTime(2026, 7, 1),
        newDate: DateTime(2026, 7, 12),
      ),
    ).called(1);
  });
}
