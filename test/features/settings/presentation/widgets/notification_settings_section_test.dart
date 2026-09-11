import 'package:billetudo/core/l10n/gen/app_localizations.dart';
import 'package:billetudo/core/notifications/domain/entities/notification_kind.dart';
import 'package:billetudo/core/notifications/domain/usecases/open_notification_system_settings.dart';
import 'package:billetudo/core/notifications/domain/usecases/read_notification_permission.dart';
import 'package:billetudo/core/notifications/domain/usecases/read_notification_preferences.dart';
import 'package:billetudo/core/notifications/domain/usecases/set_notification_kind_enabled.dart';
import 'package:billetudo/core/theme/app_theme.dart';
import 'package:billetudo/core/widgets/app_switch.dart';
import 'package:billetudo/core/widgets/toggle_field.dart';
import 'package:billetudo/features/settings/presentation/cubit/notification_settings_cubit.dart';
import 'package:billetudo/features/settings/presentation/widgets/notification_permission_denied_notice.dart';
import 'package:billetudo/features/settings/presentation/widgets/notification_settings_section.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../core/notifications/notification_test_doubles.dart';

/// `z8RdTm` (normal) y `VkWqs` (permiso del sistema denegado).
void main() {
  late FakeNotificationPreferences preferences;
  late FakeNotificationScheduler scheduler;

  NotificationSettingsCubit buildCubit() => NotificationSettingsCubit(
        ReadNotificationPreferences(preferences),
        SetNotificationKindEnabled(preferences),
        noopSyncReminders(),
        ReadNotificationPermission(scheduler),
        OpenNotificationSystemSettings(scheduler),
      );

  setUp(() {
    preferences = FakeNotificationPreferences();
    scheduler = FakeNotificationScheduler();
  });

  Future<NotificationSettingsCubit> pumpSection(WidgetTester tester) async {
    final cubit = buildCubit();
    await cubit.start();
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        locale: const Locale('es'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: SingleChildScrollView(
            child: BlocProvider<NotificationSettingsCubit>.value(
              value: cubit,
              child: const NotificationSettingsSection(),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    return cubit;
  }

  testWidgets('con permiso: un interruptor por tipo, sin tira de aviso',
      (tester) async {
    final cubit = await pumpSection(tester);

    expect(find.byType(NotificationPermissionDeniedNotice), findsNothing);
    expect(
      find.byType(ToggleField),
      findsNWidgets(NotificationKind.values.length),
    );
    for (final switchWidget in tester.widgetList<AppSwitch>(
      find.byType(AppSwitch),
    )) {
      expect(switchWidget.inert, isFalse);
    }

    await cubit.close();
  });

  testWidgets('con permiso el interruptor apaga solo su tipo', (tester) async {
    final cubit = await pumpSection(tester);

    await tester.tap(find.text('Hitos de metas'));
    await tester.pump();

    expect(
      await preferences.isEnabled(NotificationKind.goalMilestones),
      isFalse,
    );
    expect(
      await preferences.isEnabled(NotificationKind.paymentReminders),
      isTrue,
    );

    await cubit.close();
  });

  testWidgets(
      'permiso denegado: tira ámbar, CTA a los ajustes e interruptores '
      'inertes', (tester) async {
    scheduler.permissionGranted = false;
    final cubit = await pumpSection(tester);

    expect(find.byType(NotificationPermissionDeniedNotice), findsOneWidget);
    expect(find.text('Tu teléfono tiene las notificaciones apagadas'),
        findsOneWidget);

    // Inertes, no apagados en almacenamiento: el estado se cifra en la
    // posición del knob, no en opacidad.
    for (final switchWidget in tester.widgetList<AppSwitch>(
      find.byType(AppSwitch),
    )) {
      expect(switchWidget.inert, isTrue);
    }

    await tester.tap(find.text('Abrir ajustes del teléfono'));
    await tester.pump();
    expect(scheduler.systemSettingsOpened, isTrue);

    await cubit.close();
  });

  testWidgets('permiso denegado: tocar un interruptor no cambia nada',
      (tester) async {
    scheduler.permissionGranted = false;
    final cubit = await pumpSection(tester);

    await tester.tap(find.text('Hitos de metas'));
    await tester.pump();

    // La preferencia guardada sobrevive intacta: al reconceder el permiso
    // vuelve como estaba.
    expect(
      await preferences.isEnabled(NotificationKind.goalMilestones),
      isTrue,
    );
    expect(preferences.values, isEmpty);

    await cubit.close();
  });
}
