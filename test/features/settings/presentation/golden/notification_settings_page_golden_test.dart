import 'package:billetudo/features/settings/presentation/cubit/notification_settings_cubit.dart';
import 'package:billetudo/features/settings/presentation/cubit/notification_settings_state.dart';
import 'package:billetudo/features/settings/presentation/pages/notification_settings_page.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../support/golden_helpers.dart';

class MockNotificationSettingsCubit extends MockCubit<NotificationSettingsState>
    implements NotificationSettingsCubit {}

/// "Ajustes ▸ Notificaciones", los dos estados que existen en el diseño:
///
/// - `z8RdTm`: permiso concedido, un interruptor por tipo de aviso.
/// - `VkWqs`: permiso del SISTEMA denegado — tira `$amber-soft`, CTA neutro a
///   los ajustes del teléfono e interruptores inertes (`Switch/Off`), nunca
///   atenuados por opacidad.
void main() {
  setUpAll(() async {
    disableGoogleFontsRuntimeFetching();
    await loadMaterialIconsFont();
  });

  Future<void> golden(
    WidgetTester tester,
    String name, {
    required Brightness brightness,
    required bool permissionGranted,
  }) async {
    final state = NotificationSettingsState(
      loaded: true,
      permissionGranted: permissionGranted,
    );
    final cubit = MockNotificationSettingsCubit();
    when(() => cubit.state).thenReturn(state);
    whenListen(
      cubit,
      const Stream<NotificationSettingsState>.empty(),
      initialState: state,
    );

    await pumpGolden(
      tester,
      BlocProvider<NotificationSettingsCubit>.value(
        value: cubit,
        child: const NotificationSettingsPage(),
      ),
      brightness: brightness,
      // Cuatro tarjetas con hint + la tira de permiso no caben en 844.
      size: tallGoldenPhoneSize(height: 1100),
    );

    await expectLater(
      find.byType(NotificationSettingsPage),
      matchesGoldenFile('goldens/$name.png'),
    );
  }

  testWidgets('permiso concedido (light)', (tester) async {
    await golden(
      tester,
      'notification_settings_page_granted_light',
      brightness: Brightness.light,
      permissionGranted: true,
    );
  });

  testWidgets('permiso concedido (dark)', (tester) async {
    await golden(
      tester,
      'notification_settings_page_granted_dark',
      brightness: Brightness.dark,
      permissionGranted: true,
    );
  });

  testWidgets('permiso del sistema denegado (light)', (tester) async {
    await golden(
      tester,
      'notification_settings_page_denied_light',
      brightness: Brightness.light,
      permissionGranted: false,
    );
  });

  testWidgets('permiso del sistema denegado (dark)', (tester) async {
    await golden(
      tester,
      'notification_settings_page_denied_dark',
      brightness: Brightness.dark,
      permissionGranted: false,
    );
  });
}
