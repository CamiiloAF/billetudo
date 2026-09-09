import 'package:billetudo/core/notifications/domain/entities/notification_kind.dart';
import 'package:billetudo/core/notifications/domain/usecases/read_notification_preferences.dart';
import 'package:billetudo/core/notifications/domain/usecases/set_notification_kind_enabled.dart';
import 'package:billetudo/features/settings/presentation/cubit/notification_settings_cubit.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../core/notifications/notification_test_doubles.dart';

void main() {
  late FakeNotificationPreferences preferences;
  late MockSyncScheduledPaymentReminders syncReminders;

  NotificationSettingsCubit build() => NotificationSettingsCubit(
        ReadNotificationPreferences(preferences),
        SetNotificationKindEnabled(preferences),
        syncReminders,
      );

  setUp(() {
    preferences = FakeNotificationPreferences();
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
}
