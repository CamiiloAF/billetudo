import 'package:billetudo/core/error/result.dart';
import 'package:billetudo/features/scheduled_payments/domain/entities/scheduled_payment.dart';
import 'package:billetudo/features/scheduled_payments/domain/entities/scheduled_payment_summary.dart';
import 'package:billetudo/features/scheduled_payments/domain/repositories/scheduled_payment_repository.dart';
import 'package:billetudo/features/scheduled_payments/domain/usecases/get_scheduled_payments.dart';
import 'package:billetudo/features/scheduled_payments/domain/usecases/project_upcoming_occurrences.dart';
import 'package:clock/clock.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../scheduled_payment_fixtures.dart';

class MockScheduledPaymentRepository extends Mock
    implements ScheduledPaymentRepository {}

void main() {
  late MockScheduledPaymentRepository repository;
  late GetScheduledPayments useCase;

  // Fixed "now" so the "this month + next month" forward window is
  // deterministic. Templates below are anchored relative to it.
  final now = DateTime(2026, 1, 1);

  setUp(() {
    repository = MockScheduledPaymentRepository();
    useCase =
        GetScheduledPayments(repository, const ProjectUpcomingOccurrences());
  });

  Stream<Result<List<ScheduledPaymentSummary>>> streamOf(
    List<ScheduledPaymentSummary> items,
  ) =>
      Stream.value(Right(items));

  test(
    'a monthly template whose nextDate cursor fell behind still projects its '
    'real future dates instead of showing the stale cursor (the reported bug)',
    () {
      withClock(Clock.fixed(now), () {
        // The persisted cursor is stale (e.g. a missed catch-up run): it
        // still points at a date several cycles behind "now".
        final stale = buildScheduledPayment(
          nextDate: DateTime(2025, 9, 1),
          frequency: ScheduledPaymentFrequency.monthly,
        );
        final summary =
            ScheduledPaymentSummary(scheduledPayment: stale, accountName: 'Nu');
        when(() => repository.watchActiveScheduledPayments())
            .thenAnswer((_) => streamOf([summary]));

        expect(
          useCase(),
          emits(
            isA<Result<List<ScheduledPaymentSummary>>>().having(
              (r) => r.getOrElse((_) => const []).map((e) => e.nextPaymentDate),
              'projected dates',
              // 2025-09-01 monthly forward lands on 2026-01-01 (today) and
              // 2026-02-01 — both within "this month + next month" (window
              // ends Feb 28, 2026). March's date falls outside it.
              [
                DateTime(2026),
                DateTime(2026, 2),
              ],
            ),
          ),
        );
      });
    },
  );

  test(
    'a template with a due occurrence is passed through untouched, no '
    'projection applied',
    () {
      withClock(Clock.fixed(now), () {
        final template = buildScheduledPayment(nextDate: now);
        final summary = ScheduledPaymentSummary(
          scheduledPayment: template,
          accountName: 'Nu',
          pendingOccurrenceCount: 1,
          nextAwaitingDate: now,
        );
        when(() => repository.watchActiveScheduledPayments())
            .thenAnswer((_) => streamOf([summary]));

        expect(
          useCase(),
          emits(
            isA<Result<List<ScheduledPaymentSummary>>>().having(
              (r) => r.getOrElse((_) => const []),
              'items',
              [summary],
            ),
          ),
        );
      });
    },
  );

  test(
    'a future awaiting (snoozed) occurrence keeps its own row and is never '
    'duplicated by the projection landing on the same day',
    () {
      withClock(Clock.fixed(now), () {
        final template = buildScheduledPayment(
          nextDate: DateTime(2026, 1, 10),
          frequency: ScheduledPaymentFrequency.monthly,
        );
        final summary = ScheduledPaymentSummary(
          scheduledPayment: template,
          accountName: 'Nu',
          // The template's own cadence date was snoozed forward to the 10th
          // — same day the projection would also produce from `nextDate`.
          nextAwaitingDate: DateTime(2026, 1, 10),
        );
        when(() => repository.watchActiveScheduledPayments())
            .thenAnswer((_) => streamOf([summary]));

        expect(
          useCase(),
          emits(
            isA<Result<List<ScheduledPaymentSummary>>>().having(
              (r) => r.getOrElse((_) => const []).map((e) => e.nextPaymentDate),
              'projected dates',
              // The Jan 10 row comes from the awaiting occurrence, not a
              // duplicate projection; Feb 10 is still projected (Mar 10
              // falls outside the "this month + next month" window).
              [
                DateTime(2026, 1, 10),
                DateTime(2026, 2, 10),
              ],
            ),
          ),
        );
      });
    },
  );

  test(
    'a template whose next real date sits farther than the window still '
    'shows up, with its raw cursor, instead of disappearing',
    () {
      withClock(Clock.fixed(now), () {
        final template = buildScheduledPayment(
          nextDate: DateTime(2026, 6, 1),
          frequency: ScheduledPaymentFrequency.yearly,
        );
        final summary = ScheduledPaymentSummary(
            scheduledPayment: template, accountName: 'Nu');
        when(() => repository.watchActiveScheduledPayments())
            .thenAnswer((_) => streamOf([summary]));

        expect(
          useCase(),
          emits(
            isA<Result<List<ScheduledPaymentSummary>>>().having(
              (r) => r.getOrElse((_) => const []),
              'items',
              [summary],
            ),
          ),
        );
      });
    },
  );

  test('a repository failure is propagated untouched', () {
    withClock(Clock.fixed(now), () {
      when(() => repository.watchActiveScheduledPayments()).thenAnswer(
        (_) => Stream.value(const Left(DatabaseFailure('boom'))),
      );

      expect(
        useCase(),
        emits(
          isA<Result<List<ScheduledPaymentSummary>>>()
              .having((r) => r.isLeft(), 'isLeft', isTrue),
        ),
      );
    });
  });
}
