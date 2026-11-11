import 'package:billetudo/core/sync/presentation/cubit/sync_status_cubit.dart';
import 'package:billetudo/core/sync/presentation/cubit/sync_status_state.dart';
import 'package:billetudo/core/theme/theme_mode_cubit.dart';
import 'package:billetudo/features/auth/domain/entities/auth_provider.dart';
import 'package:billetudo/features/auth/domain/entities/auth_session.dart';
import 'package:billetudo/features/auth/domain/entities/auth_user.dart';
import 'package:billetudo/features/auth/domain/usecases/sign_out.dart';
import 'package:billetudo/features/auth/domain/usecases/watch_auth_session.dart';
import 'package:billetudo/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:billetudo/features/capture/presentation/cubit/capture_background_cubit.dart';
import 'package:billetudo/features/capture/presentation/cubit/capture_background_state.dart';
import 'package:billetudo/features/capture/presentation/cubit/capture_status_cubit.dart';
import 'package:billetudo/features/capture/presentation/cubit/capture_status_state.dart';
import 'package:billetudo/features/settings/presentation/cubit/app_settings_cubit.dart';
import 'package:billetudo/features/settings/presentation/cubit/app_settings_state.dart';
import 'package:billetudo/features/settings/presentation/cubit/notification_settings_cubit.dart';
import 'package:billetudo/features/settings/presentation/cubit/notification_settings_state.dart';
import 'package:billetudo/features/settings/presentation/pages/settings_page.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../support/golden_helpers.dart';
import '../../../capture/capture_mocks.dart';

class MockWatchAuthSession extends Mock implements WatchAuthSession {}

class MockSignOut extends Mock implements SignOut {}

class MockAppSettingsCubit extends MockCubit<AppSettingsState>
    implements AppSettingsCubit {}

class MockThemeModeCubit extends MockCubit<ThemeMode>
    implements ThemeModeCubit {}

class MockSyncStatusCubit extends MockCubit<SyncStatusState>
    implements SyncStatusCubit {}

/// Seeded `isSupported: true`: the golden shows the Android page, which is
/// where both capture rows exist (the platform the HU-09 surfaces ship to).
/// The iOS "draws nothing" behaviour is asserted in the widget and page tests,
/// not in the golden.
class MockCaptureStatusCubit extends MockCubit<CaptureStatusState>
    implements CaptureStatusCubit {}

class MockNotificationSettingsCubit extends MockCubit<NotificationSettingsState>
    implements NotificationSettingsCubit {}

/// Ajustes, both business states named in `design-system/billetudo/pages/auth.md`:
///
/// - Sin sesión (`jDaUb`/`j4JYF`): "Respaldar en la nube" invites Login.
/// - Con sesión (`aaQBp`/`TQHmY`): `SettingsSessionCard` replaces that row,
///   no "Cerrar sesión" (moved to "Más" — see the page's own doc comment).
///
/// Both share the rest of the page (Preferencias, the "Modo sobres" field,
/// the destructive "Eliminar cuenta" row at the very bottom), so the session
/// state is the only visually-distinguishing business state here.
void main() {
  const user = AuthUser(
    id: 'google-1',
    displayName: 'Camila Agudelo',
    provider: AuthProvider.google,
  );

  setUpAll(() async {
    disableGoogleFontsRuntimeFetching();
    await loadMaterialIconsFont();
  });

  Future<void> golden(
    WidgetTester tester,
    String name, {
    required AuthSession session,
    required Brightness brightness,
  }) async {
    final watchAuthSession = MockWatchAuthSession();
    final signOut = MockSignOut();
    when(() => watchAuthSession.current).thenReturn(session);
    when(watchAuthSession.call).thenAnswer((_) => const Stream.empty());

    final appSettingsCubit = MockAppSettingsCubit();
    when(() => appSettingsCubit.state).thenReturn(const AppSettingsState());
    whenListen(
      appSettingsCubit,
      const Stream<AppSettingsState>.empty(),
      initialState: const AppSettingsState(),
    );

    final themeModeCubit = MockThemeModeCubit();
    when(() => themeModeCubit.state).thenReturn(ThemeMode.system);
    whenListen(
      themeModeCubit,
      const Stream<ThemeMode>.empty(),
      initialState: ThemeMode.system,
    );

    final syncStatusCubit = MockSyncStatusCubit();
    when(() => syncStatusCubit.state).thenReturn(const SyncStatusState());
    whenListen(
      syncStatusCubit,
      const Stream<SyncStatusState>.empty(),
      initialState: const SyncStatusState(),
    );

    final captureStatusCubit = MockCaptureStatusCubit();
    const captureStatusState = CaptureStatusState(
      isSupported: true,
      isLoading: false,
      permissionGranted: true,
      enabledCount: 1,
    );
    when(() => captureStatusCubit.state).thenReturn(captureStatusState);
    whenListen(
      captureStatusCubit,
      const Stream<CaptureStatusState>.empty(),
      initialState: captureStatusState,
    );

    // HU-09's permanent row: the healthy state, which is what a user with
    // capture actually working sees. Its relative day is pinned to the
    // golden clock so the PNG does not drift into "7 de agosto" tomorrow.
    final captureBackgroundCubit = MockCaptureBackgroundCubit();
    final captureBackgroundState = CaptureBackgroundState(
      isSupported: true,
      isLoading: false,
      permissionGranted: true,
      enabledCount: 1,
      diagnostics: buildCaptureDiagnostics(
        lastCaptureAtEpochMs:
            DateTime(2026, 8, 7, 9, 19).millisecondsSinceEpoch,
      ),
    );
    when(() => captureBackgroundCubit.state).thenReturn(captureBackgroundState);
    whenListen(
      captureBackgroundCubit,
      const Stream<CaptureBackgroundState>.empty(),
      initialState: captureBackgroundState,
    );

    // "Avisos": todos los tipos encendidos, que es el default real.
    final notificationSettingsCubit = MockNotificationSettingsCubit();
    when(() => notificationSettingsCubit.state)
        .thenReturn(const NotificationSettingsState(loaded: true));
    whenListen(
      notificationSettingsCubit,
      const Stream<NotificationSettingsState>.empty(),
      initialState: const NotificationSettingsState(loaded: true),
    );

    await pumpWithFixedClock(
      tester,
      MultiBlocProvider(
        providers: [
          BlocProvider(create: (_) => AuthCubit(watchAuthSession, signOut)),
          BlocProvider<AppSettingsCubit>.value(value: appSettingsCubit),
          BlocProvider<ThemeModeCubit>.value(value: themeModeCubit),
          BlocProvider<SyncStatusCubit>.value(value: syncStatusCubit),
          BlocProvider<CaptureStatusCubit>.value(value: captureStatusCubit),
          BlocProvider<CaptureBackgroundCubit>.value(
            value: captureBackgroundCubit,
          ),
          BlocProvider<NotificationSettingsCubit>.value(
            value: notificationSettingsCubit,
          ),
        ],
        child: SettingsPage(
          onOpenLogin: () {},
          onOpenDeleteAccount: () {},
          onOpenComingSoon: (_) {},
          onOpenSyncStatus: () {},
          onOpenQuickAccessOrder: () {},
          onOpenCapture: (_) {},
          onOpenCaptureSetup: (_) {},
          onOpenNotifications: () {},
        ),
      ),
      brightness: brightness,
      // Full-page canvas: HU-09's "Captura en segundo plano" row lives in
      // Preferencias, below the first 844pt viewport. Capturing only the
      // viewport would leave the row this golden is meant to evidence out of
      // the PNG (and the page golden is about the whole page anyway).
      size: tallGoldenPhoneSize(height: 2000),
    );
    await expectLater(
      find.byType(SettingsPage),
      matchesGoldenFile('goldens/settings_page_$name.png'),
    );
  }

  for (final brightness in Brightness.values) {
    final suffix = brightness == Brightness.light ? 'light' : 'dark';

    testWidgets('sin sesión ($suffix)', (tester) async {
      await golden(
        tester,
        'signed_out_$suffix',
        session: const AuthSession.signedOut(),
        brightness: brightness,
      );
    });

    testWidgets('con sesión ($suffix)', (tester) async {
      await golden(
        tester,
        'signed_in_$suffix',
        session: const AuthSession.signedIn(user),
        brightness: brightness,
      );
    });
  }
}
