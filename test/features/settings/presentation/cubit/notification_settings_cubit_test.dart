import 'package:billetudo/core/notifications/domain/entities/notification_kind.dart';
import 'package:billetudo/core/notifications/domain/usecases/open_notification_system_settings.dart';
import 'package:billetudo/core/notifications/domain/usecases/read_notification_permission.dart';
import 'package:billetudo/core/notifications/domain/usecases/read_notification_preferences.dart';
import 'package:billetudo/core/notifications/domain/usecases/set_notification_kind_enabled.dart';
import 'package:billetudo/features/settings/presentation/cubit/notification_settings_cubit.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../core/notifications/notification_test_doubles.dart';

void main() {
  late FakeNotificationPreferences preferences;
  late FakeNotificationScheduler scheduler;
  late MockSyncScheduledPaymentReminders syncReminders;

  NotificationSettingsCubit build() => NotificationSettingsCubit(
        ReadNotificationPreferences(preferences),
        SetNotificationKindEnabled(preferences),
        syncReminders,
        ReadNotificationPermission(scheduler),
        OpenNotificationSystemSettings(scheduler),
      );

  setUp(() {
    preferences = FakeNotificationPreferences();
    scheduler = FakeNotificationScheduler();
    syncReminders = noopSyncReminders();
  });

  test('todos los tipos arrancan encendidos', () async {
    final cubit = build();

    await cubit.start();

    for (final kind in NotificationKind.values) {
      expect(cubit.state.isEnabled(kind), isTrue);
    }
    await cubit.close();
  });

  test('apagar un tipo lo persiste', () async {
    final cubit = build();
    await cubit.start();

    await cubit.setEnabled(
      NotificationKind.goalMilestones,
      enabled: false,
    );

    expect(cubit.state.isEnabled(NotificationKind.goalMilestones), isFalse);
    expect(
        await preferences.isEnabled(NotificationKind.goalMilestones), isFalse);
    await cubit.close();
  });

  test(
      'apagar los recordatorios reconcilia de inmediato, sin esperar al '
      'siguiente arranque', () async {
    final cubit = build();
    await cubit.start();

    await cubit.setEnabled(
      NotificationKind.paymentReminders,
      enabled: false,
    );

    verify(syncReminders.call).called(1);
    await cubit.close();
  });

  // `VkWqs`: con el permiso del sistema revocado los interruptores no pueden
  // seguir mostrandose encendidos como si algo fuera a llegar.
  group('permiso del sistema', () {
    test('start lo lee sin pedirlo', () async {
      scheduler.permissionGranted = false;
      final cubit = build();

      await cubit.start();

      expect(cubit.state.permissionGranted, isFalse);
      // Leer no puede disparar el diálogo del sistema: un prompt sin motivo
      // visible es el que se deniega para siempre.
      expect(scheduler.permissionRequested, isFalse);
      await cubit.close();
    });

    test('denegado conserva intactas las preferencias guardadas', () async {
      await preferences.setEnabled(
        NotificationKind.goalMilestones,
        enabled: false,
      );
      scheduler.permissionGranted = false;
      final cubit = build();

      await cubit.start();

      expect(cubit.state.permissionGranted, isFalse);
      expect(cubit.state.isEnabled(NotificationKind.goalMilestones), isFalse);
      expect(cubit.state.isEnabled(NotificationKind.paymentReminders), isTrue);
      await cubit.close();
    });

    test('al volver de los ajustes del teléfono se relee', () async {
      scheduler.permissionGranted = false;
      final cubit = build();
      await cubit.start();
      expect(cubit.state.permissionGranted, isFalse);

      scheduler.permissionGranted = true;
      await cubit.refreshPermission();

      expect(cubit.state.permissionGranted, isTrue);
      await cubit.close();
    });

    test('el CTA lleva a los ajustes del sistema', () async {
      final cubit = build();
      await cubit.start();

      await cubit.openSystemSettings();

      expect(scheduler.systemSettingsOpened, isTrue);
      await cubit.close();
    });
  });
}
