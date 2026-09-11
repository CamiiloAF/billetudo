import 'package:billetudo/core/error/result.dart';
import 'package:billetudo/core/notifications/domain/entities/notification_kind.dart';
import 'package:billetudo/features/goals/domain/entities/goal.dart';
import 'package:billetudo/features/goals/domain/entities/goal_with_progress.dart';
import 'package:billetudo/features/goals/domain/usecases/watch_goals.dart';
import 'package:billetudo/features/improvement/domain/entities/insight.dart';
import 'package:billetudo/features/improvement/domain/entities/insight_thresholds.dart';
import 'package:billetudo/features/improvement/domain/usecases/watch_goal_milestone_insights.dart';
import 'package:billetudo/features/improvement/domain/usecases/watch_insights.dart';
import 'package:billetudo/features/improvement/domain/usecases/watch_pending_confirmation_insights.dart';
import 'package:billetudo/features/improvement/domain/usecases/watch_upcoming_charge_insights.dart';
import 'package:billetudo/features/scheduled_payments/domain/entities/pending_scheduled_occurrence.dart';
import 'package:billetudo/features/scheduled_payments/domain/entities/scheduled_payment.dart';
import 'package:billetudo/features/scheduled_payments/domain/entities/scheduled_payment_summary.dart';
import 'package:billetudo/features/scheduled_payments/domain/usecases/get_pending_occurrences.dart';
import 'package:billetudo/features/scheduled_payments/domain/usecases/get_scheduled_payments.dart';
import 'package:billetudo/features/scheduled_payments/domain/usecases/project_upcoming_occurrences.dart';
import 'package:clock/clock.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../core/notifications/notification_test_doubles.dart';
import '../../../scheduled_payments/scheduled_payment_fixtures.dart';

class _MockGetScheduledPayments extends Mock implements GetScheduledPayments {}

class _MockGetPendingOccurrences extends Mock
    implements GetPendingOccurrences {}

class _MockWatchGoals extends Mock implements WatchGoals {}

void main() {
  final now = DateTime(2026, 7, 15, 10, 30);

  late _MockGetScheduledPayments getScheduledPayments;
  late _MockGetPendingOccurrences getPendingOccurrences;
  late _MockWatchGoals watchGoals;
  late FakeNotificationPreferences preferences;

  ScheduledPaymentSummary summary({
    String id = 'sp-1',
    String note = 'Netflix',
    int amountMinor = 30000,
    DateTime? nextDate,
    int pendingOccurrenceCount = 0,
  }) =>
      ScheduledPaymentSummary(
        scheduledPayment: buildScheduledPayment(
          id: id,
          note: note,
          amountMinor: amountMinor,
          nextDate: nextDate ?? DateTime(2026, 7, 18),
        ),
        accountName: 'Nequi',
        pendingOccurrenceCount: pendingOccurrenceCount,
      );

  GoalWithProgress goal({
    String id = 'g-1',
    String name = 'Viaje',
    int lastMilestonePct = 50,
    int savedMinor = 500000,
    DateTime? updatedAt,
    DateTime? completedAt,
  }) =>
      GoalWithProgress(
        goal: Goal(
          id: id,
          name: name,
          targetMinor: 1000000,
          currency: 'COP',
          lastMilestonePct: lastMilestonePct,
          createdAt: DateTime(2026),
          updatedAt: (updatedAt ?? now).millisecondsSinceEpoch,
          completedAt: completedAt,
        ),
        savedMinor: savedMinor,
        displayedPercent: lastMilestonePct,
        remainingMinor: 1000000 - savedMinor,
      );

  void stubTemplates(List<ScheduledPaymentSummary> items) {
    when(getScheduledPayments.call)
        .thenAnswer((_) => Stream.value(Right(items)));
  }

  void stubPending(List<PendingScheduledOccurrence> items) {
    when(getPendingOccurrences.call)
        .thenAnswer((_) => Stream.value(Right(items)));
  }

  void stubGoals(List<GoalWithProgress> items) {
    when(watchGoals.call).thenAnswer((_) => Stream.value(Right(items)));
  }

  setUp(() {
    getScheduledPayments = _MockGetScheduledPayments();
    getPendingOccurrences = _MockGetPendingOccurrences();
    watchGoals = _MockWatchGoals();
    preferences = FakeNotificationPreferences();
    stubTemplates([]);
    stubPending([]);
    stubGoals([]);
  });

  Future<List<Insight>> upcoming() => withClock(
        Clock.fixed(now),
        () async {
          final result = await WatchUpcomingChargeInsights(
            getScheduledPayments,
            const ProjectUpcomingOccurrences(),
          )().first;
          return result.getOrElse((_) => const <Insight>[]);
        },
      );

  Future<List<Insight>> pending() => withClock(
        Clock.fixed(now),
        () async {
          final result =
              await WatchPendingConfirmationInsights(getPendingOccurrences)()
                  .first;
          return result.getOrElse((_) => const <Insight>[]);
        },
      );

  Future<List<Insight>> milestones() => withClock(
        Clock.fixed(now),
        () async {
          final result = await WatchGoalMilestoneInsights(watchGoals)().first;
          return result.getOrElse((_) => const <Insight>[]);
        },
      );

  Future<List<Insight>> all() => withClock(
        Clock.fixed(now),
        () async {
          final result = await WatchInsights(
            WatchUpcomingChargeInsights(
              getScheduledPayments,
              const ProjectUpcomingOccurrences(),
            ),
            WatchPendingConfirmationInsights(getPendingOccurrences),
            WatchGoalMilestoneInsights(watchGoals),
            preferences,
          )().first;
          return result.getOrElse((_) => const <Insight>[]);
        },
      );

  group('cobro próximo', () {
    test('avisa de un cobro dentro del horizonte, con su fecha y monto',
        () async {
      stubTemplates([summary(nextDate: DateTime(2026, 7, 18))]);

      final insights = await upcoming();

      expect(insights, hasLength(1));
      expect(insights.single.type, InsightType.upcomingCharge);
      expect(insights.single.subject, 'Netflix');
      expect(insights.single.daysUntil, 3);
      expect(insights.single.amountMinor, 30000);
    });

    test('ignora un cobro más allá del horizonte', () async {
      stubTemplates([summary(nextDate: DateTime(2026, 8, 18))]);

      expect(await upcoming(), isEmpty);
    });

    test('umbral duro de monto: un cobro insignificante no genera aviso',
        () async {
      stubTemplates([
        summary(amountMinor: InsightThresholds.minimumAmountMinor - 1),
      ]);

      expect(await upcoming(), isEmpty);
    });

    test('no duplica lo que ya está pendiente de confirmar', () async {
      stubTemplates([summary(pendingOccurrenceCount: 1)]);

      expect(await upcoming(), isEmpty);
    });

    test('una plantilla diaria aporta un único aviso, no siete', () async {
      stubTemplates([
        ScheduledPaymentSummary(
          scheduledPayment: buildScheduledPayment(
            note: 'Café',
            amountMinor: 30000,
            frequency: ScheduledPaymentFrequency.daily,
            nextDate: DateTime(2026, 7, 16),
          ),
          accountName: 'Nequi',
        ),
      ]);

      final insights = await upcoming();

      expect(insights, hasLength(1));
      expect(insights.single.daysUntil, 1);
    });
  });

  group('pendiente de confirmar', () {
    test('genera un aviso accionable por ocurrencia vencida', () async {
      stubPending([
        buildPendingOccurrence(
          occurrence: buildOccurrence(
            occurrenceDate: DateTime(2026, 7, 14),
          ),
          scheduledPayment: buildScheduledPayment(
            note: 'Arriendo',
            requiresConfirmation: true,
          ),
        ),
      ]);

      final insights = await pending();

      expect(insights, hasLength(1));
      expect(insights.single.type, InsightType.pendingConfirmation);
      expect(insights.single.subject, 'Arriendo');
    });
  });

  group('hito de meta', () {
    test('celebra un hito reciente', () async {
      stubGoals([goal(lastMilestonePct: 75)]);

      final insights = await milestones();

      expect(insights, hasLength(1));
      expect(insights.single.progressPercent, 75);
      expect(insights.single.subject, 'Viaje');
    });

    test('no celebra el 25%: demasiado pronto para ser un logro', () async {
      stubGoals([goal(lastMilestonePct: 25)]);

      expect(await milestones(), isEmpty);
    });

    test('no celebra un hito viejo: eso es historia, no novedad', () async {
      stubGoals([
        goal(updatedAt: now.subtract(const Duration(days: 40))),
      ]);

      expect(await milestones(), isEmpty);
    });

    test('marca la meta terminada como logro completo', () async {
      stubGoals([
        goal(lastMilestonePct: 100, savedMinor: 1000000, completedAt: now),
      ]);

      final insights = await milestones();

      expect(insights.single.isGoalCompletion, isTrue);
    });
  });

  group('WatchInsights', () {
    test('ordena por utilidad: primero lo accionable, al final lo celebratorio',
        () async {
      stubTemplates([summary()]);
      stubPending([buildPendingOccurrence()]);
      stubGoals([goal()]);

      final insights = await all();

      expect(
        insights.map((insight) => insight.type),
        [
          InsightType.pendingConfirmation,
          InsightType.upcomingCharge,
          InsightType.goalMilestone,
        ],
      );
    });

    test('respeta la preferencia por tipo de Ajustes', () async {
      stubTemplates([summary()]);
      stubGoals([goal()]);
      preferences.values[NotificationKind.goalMilestones] = false;

      final insights = await all();

      expect(
        insights.every((insight) => insight.type != InsightType.goalMilestone),
        isTrue,
      );
    });

    test('aplica el tope de frecuencia', () async {
      stubTemplates([
        for (var i = 0; i < 10; i++)
          summary(id: 'sp-$i', note: 'Pago $i'),
      ]);

      final insights = await all();

      expect(insights, hasLength(InsightThresholds.maxInsights));
    });
  });
}
