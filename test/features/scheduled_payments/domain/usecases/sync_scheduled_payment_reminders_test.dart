import 'package:billetudo/core/error/result.dart';
import 'package:billetudo/core/notifications/domain/entities/app_notification_channel.dart';
import 'package:billetudo/core/notifications/domain/entities/notification_id.dart';
import 'package:billetudo/core/notifications/domain/entities/notification_kind.dart';
import 'package:billetudo/core/notifications/domain/entities/scheduled_local_notification.dart';
import 'package:billetudo/features/scheduled_payments/domain/entities/scheduled_payment_summary.dart';
import 'package:billetudo/features/scheduled_payments/domain/usecases/sync_scheduled_payment_reminders.dart';
import 'package:clock/clock.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../core/notifications/notification_test_doubles.dart';
import '../../scheduled_payment_fixtures.dart';
import 'scheduled_payment_repository_mock.dart';

/// The reminder lifecycle (HU-08). Every case here is a way a reminder can
/// end up pointing at something that is no longer true — which is the failure
/// that teaches people to turn notifications off.
void main() {
  late MockScheduledPaymentRepository repository;
  late FakeNotificationScheduler scheduler;
  late FakeNotificationPreferences preferences;
  late SyncScheduledPaymentReminders sync;

  /// "Today" for every test: 2026-07-15 10:30.
  final now = DateTime(2026, 7, 15, 10, 30);

  int idFor(String templateId) =>
      NotificationId.forKey(templateId, AppNotificationChannel.reminders);

  ScheduledPaymentSummary summary({
    String id = 'sp-1',
    int? reminderLeadDays = 3,
    DateTime? nextDate,
    DateTime? nextAwaitingDate,
    String note = 'Netflix',
    String accountName = 'Nequi',
  }) =>
      ScheduledPaymentSummary(
        scheduledPayment: buildScheduledPayment(
          id: id,
          note: note,
          nextDate: nextDate ?? DateTime(2026, 7, 20),
          reminderLeadDays: reminderLeadDays,
        ),
        accountName: accountName,
        nextAwaitingDate: nextAwaitingDate,
      );

  void stubActive(List<ScheduledPaymentSummary> summaries) {
    when(repository.watchActiveScheduledPayments)
        .thenAnswer((_) => Stream.value(Right(summaries)));
  }

  FutureResult<Unit> run() => withClock(Clock.fixed(now), () => sync());

  setUp(() {
    repository = MockScheduledPaymentRepository();
    scheduler = FakeNotificationScheduler();
    preferences = FakeNotificationPreferences();
    sync = SyncScheduledPaymentReminders(
      repository,
      scheduler,
      preferences,
      FakeNotificationMessages(),
    );
  });

  group('programar', () {
    test('programa el recordatorio a las 09:00 del día - anticipación',
        () async {
      stubActive([summary(nextDate: DateTime(2026, 7, 20))]);

      final result = await run();

      expect(result.isRight(), isTrue);
      final scheduled = scheduler.scheduled[idFor('sp-1')];
      expect(scheduled, isNotNull);
      // 20 de julio menos 3 días = 17 de julio, 09:00 hora local.
      expect(scheduled!.fireAt, DateTime(2026, 7, 17, 9));
      expect(scheduled.channel, AppNotificationChannel.reminders);
      expect(scheduled.title, 'Netflix');
      expect(scheduled.body, contains('lead=3'));
      expect(scheduled.body, contains('Nequi'));
      expect(scheduled.payload, 'sp-1');
    });

    test('una plantilla sin recordatorio no programa nada', () async {
      stubActive([summary(reminderLeadDays: null)]);

      await run();

      expect(scheduler.scheduled, isEmpty);
    });

    test('usa la fecha pospuesta, no el cursor de la plantilla', () async {
      stubActive([
        summary(
          nextDate: DateTime(2026, 7, 16),
          nextAwaitingDate: DateTime(2026, 7, 25),
        ),
      ]);

      await run();

      expect(
          scheduler.scheduled[idFor('sp-1')]!.fireAt, DateTime(2026, 7, 22, 9));
    });

    test('no programa nada si la ventana de anticipación ya pasó', () async {
      // Vence mañana con 3 días de anticipación: el aviso era el 13.
      stubActive([summary(nextDate: DateTime(2026, 7, 16))]);

      await run();

      expect(scheduler.scheduled, isEmpty);
    });

    test('el id es estable entre corridas: reprogramar no duplica', () async {
      stubActive([summary(nextDate: DateTime(2026, 7, 20))]);
      await run();

      stubActive([summary(nextDate: DateTime(2026, 8, 20))]);
      await run();

      expect(scheduler.scheduled.keys.toList(), [idFor('sp-1')]);
      expect(
          scheduler.scheduled[idFor('sp-1')]!.fireAt, DateTime(2026, 8, 17, 9));
    });
  });

  group('cancelar', () {
    test(
        'una plantilla que ya no está activa (borrada, pausada o terminada) '
        'pierde su recordatorio', () async {
      stubActive([summary(nextDate: DateTime(2026, 7, 20))]);
      await run();
      expect(scheduler.scheduled, isNotEmpty);

      // La plantilla desaparece de la lista de activas: es exactamente lo que
      // pasa al borrarla (tombstone), al pasar su `endDate` o al resolver una
      // plantilla `once`.
      stubActive([]);
      await run();

      expect(scheduler.scheduled, isEmpty);
      expect(scheduler.cancelledIds, contains(idFor('sp-1')));
    });

    test('quitar el recordatorio de la plantilla cancela el pendiente',
        () async {
      stubActive([summary(nextDate: DateTime(2026, 7, 20))]);
      await run();

      stubActive([
        summary(nextDate: DateTime(2026, 7, 20), reminderLeadDays: null),
      ]);
      await run();

      expect(scheduler.scheduled, isEmpty);
      expect(scheduler.cancelledIds, contains(idFor('sp-1')));
    });

    test('apagar los recordatorios en Ajustes cancela todo lo pendiente',
        () async {
      stubActive([summary(nextDate: DateTime(2026, 7, 20))]);
      await run();

      preferences.values[NotificationKind.paymentReminders] = false;
      await run();

      expect(scheduler.scheduled, isEmpty);
    });

    test('no toca notificaciones de otros canales', () async {
      final foreignId =
          NotificationId.forKey('goal-1', AppNotificationChannel.milestones);
      await scheduler.schedule(
        ScheduledLocalNotification(
          id: foreignId,
          channel: AppNotificationChannel.milestones,
          title: 'Meta',
          body: 'Hito',
          fireAt: DateTime(2026, 7, 20, 9),
        ),
      );
      stubActive([]);

      await run();

      expect(scheduler.scheduled.containsKey(foreignId), isTrue);
    });
  });

  test('propaga el fallo del repositorio sin programar nada', () async {
    when(repository.watchActiveScheduledPayments).thenAnswer(
      (_) => Stream.value(const Left(DatabaseFailure('boom'))),
    );

    final result = await run();

    expect(result.isLeft(), isTrue);
    expect(scheduler.scheduled, isEmpty);
  });
}
