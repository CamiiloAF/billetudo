import 'package:billetudo/core/error/result.dart';
import 'package:billetudo/core/notifications/domain/entities/app_notification_channel.dart';
import 'package:billetudo/core/notifications/domain/entities/notification_id.dart';
import 'package:billetudo/core/notifications/domain/entities/scheduled_local_notification.dart';
import 'package:billetudo/features/scheduled_payments/domain/usecases/cancel_scheduled_payment_reminder.dart';
import 'package:billetudo/features/scheduled_payments/domain/usecases/delete_scheduled_payment.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../core/notifications/notification_test_doubles.dart';
import 'scheduled_payment_repository_mock.dart';

/// HU-08, explicit user requirement: "si un pago programado se elimina,
/// también se debería eliminar su recordatorio programado". A notification
/// ringing for a payment that no longer exists is the exact failure that
/// trains people to turn notifications off.
void main() {
  late FakeNotificationScheduler scheduler;
  late CancelScheduledPaymentReminder cancelReminder;

  int idFor(String templateId) =>
      NotificationId.forKey(templateId, AppNotificationChannel.reminders);

  Future<void> armReminderFor(String templateId) => scheduler.schedule(
        ScheduledLocalNotification(
          id: idFor(templateId),
          channel: AppNotificationChannel.reminders,
          title: 'Netflix',
          body: 'En 3 días',
          fireAt: DateTime(2026, 7, 17, 9),
        ),
      );

  setUp(() {
    scheduler = FakeNotificationScheduler();
    cancelReminder = CancelScheduledPaymentReminder(scheduler);
  });

  test('cancela exactamente el recordatorio de esa plantilla', () async {
    await armReminderFor('sp-1');
    await armReminderFor('sp-2');

    final result = await cancelReminder('sp-1');

    expect(result.isRight(), isTrue);
    expect(scheduler.scheduled.containsKey(idFor('sp-1')), isFalse);
    expect(scheduler.scheduled.containsKey(idFor('sp-2')), isTrue);
  });

  test('es idempotente: cancelar sin nada pendiente no falla', () async {
    final result = await cancelReminder('sp-1');

    expect(result.isRight(), isTrue);
  });

  group('borrar la plantilla', () {
    late MockScheduledPaymentRepository repository;

    setUp(() {
      repository = MockScheduledPaymentRepository();
    });

    test('borrar un pago programado cancela su recordatorio', () async {
      await armReminderFor('sp-1');
      when(() => repository.deleteScheduledPayment('sp-1'))
          .thenAnswer((_) async => const Right(unit));
      final delete = DeleteScheduledPayment(
        repository,
        cancelReminder,
        noopSyncReminders(),
      );

      final result = await delete('sp-1');

      expect(result.isRight(), isTrue);
      expect(scheduler.scheduled, isEmpty);
      expect(scheduler.cancelledIds, contains(idFor('sp-1')));
    });

    test('si el borrado falla, el recordatorio sigue en pie', () async {
      await armReminderFor('sp-1');
      when(() => repository.deleteScheduledPayment('sp-1')).thenAnswer(
        (_) async => const Left(DatabaseFailure('boom')),
      );
      final delete = DeleteScheduledPayment(
        repository,
        cancelReminder,
        noopSyncReminders(),
      );

      final result = await delete('sp-1');

      expect(result.isLeft(), isTrue);
      // La plantilla sigue existiendo, así que su aviso también debe seguir:
      // cancelarlo aquí dejaría al usuario sin el recordatorio de un pago que
      // nunca se borró.
      expect(scheduler.scheduled.containsKey(idFor('sp-1')), isTrue);
    });
  });
}
