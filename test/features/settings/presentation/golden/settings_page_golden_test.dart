import 'package:billetudo/core/theme/theme_mode_cubit.dart';
import 'package:billetudo/features/auth/domain/entities/auth_provider.dart';
import 'package:billetudo/features/auth/domain/entities/auth_session.dart';
import 'package:billetudo/features/auth/domain/entities/auth_user.dart';
import 'package:billetudo/features/auth/domain/usecases/sign_out.dart';
import 'package:billetudo/features/auth/domain/usecases/watch_auth_session.dart';
import 'package:billetudo/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:billetudo/features/settings/presentation/cubit/app_settings_cubit.dart';
import 'package:billetudo/features/settings/presentation/cubit/app_settings_state.dart';
import 'package:billetudo/features/settings/presentation/pages/settings_page.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../support/golden_helpers.dart';

class MockWatchAuthSession extends Mock implements WatchAuthSession {}

class MockSignOut extends Mock implements SignOut {}

class MockAppSettingsCubit extends MockCubit<AppSettingsState>
    implements AppSettingsCubit {}

class MockThemeModeCubit extends MockCubit<ThemeMode>
    implements ThemeModeCubit {}

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

    await pumpGolden(
      tester,
      MultiBlocProvider(
        providers: [
          BlocProvider(create: (_) => AuthCubit(watchAuthSession, signOut)),
          BlocProvider<AppSettingsCubit>.value(value: appSettingsCubit),
          BlocProvider<ThemeModeCubit>.value(value: themeModeCubit),
        ],
        child: SettingsPage(
          onOpenLogin: () {},
          onOpenDeleteAccount: () {},
          onOpenComingSoon: (_) {},
        ),
      ),
      brightness: brightness,
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
