import 'package:billetudo/features/auth/domain/entities/auth_provider.dart';
import 'package:billetudo/features/auth/domain/entities/auth_session.dart';
import 'package:billetudo/features/auth/domain/entities/auth_user.dart';
import 'package:billetudo/features/auth/domain/usecases/sign_out.dart';
import 'package:billetudo/features/auth/domain/usecases/watch_auth_session.dart';
import 'package:billetudo/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:billetudo/features/settings/presentation/cubit/app_settings_cubit.dart';
import 'package:billetudo/features/settings/presentation/cubit/app_settings_state.dart';
import 'package:billetudo/features/settings/presentation/pages/settings_page.dart';
import 'package:billetudo/features/settings/presentation/widgets/settings_session_card.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../../auth/presentation/widgets/pump_widget.dart';

class MockWatchAuthSession extends Mock implements WatchAuthSession {}

class MockSignOut extends Mock implements SignOut {}

class MockAppSettingsCubit extends MockCubit<AppSettingsState>
    implements AppSettingsCubit {}

void main() {
  late MockWatchAuthSession watchAuthSession;
  late MockSignOut signOut;
  late MockAppSettingsCubit appSettingsCubit;

  const user = AuthUser(
    id: 'google-1',
    displayName: 'Camila Agudelo',
    provider: AuthProvider.google,
  );

  setUp(() {
    watchAuthSession = MockWatchAuthSession();
    signOut = MockSignOut();
    appSettingsCubit = MockAppSettingsCubit();
    when(() => appSettingsCubit.state).thenReturn(const AppSettingsState());
    whenListen(
      appSettingsCubit,
      const Stream<AppSettingsState>.empty(),
      initialState: const AppSettingsState(),
    );
  });

  Future<void> pumpSettings(
    WidgetTester tester, {
    required AuthSession session,
    VoidCallback? onOpenLogin,
    VoidCallback? onOpenDeleteAccount,
    ValueChanged<String>? onOpenComingSoon,
  }) async {
    when(() => watchAuthSession.current).thenReturn(session);
    when(() => watchAuthSession()).thenAnswer((_) => const Stream.empty());

    await tester.pumpAuthWidget(
      MultiBlocProvider(
        providers: [
          BlocProvider(create: (_) => AuthCubit(watchAuthSession, signOut)),
          BlocProvider<AppSettingsCubit>.value(value: appSettingsCubit),
        ],
        child: SettingsPage(
          onOpenLogin: onOpenLogin ?? () {},
          onOpenDeleteAccount: onOpenDeleteAccount ?? () {},
          onOpenComingSoon: onOpenComingSoon ?? (_) {},
        ),
      ),
      wrapInScaffold: false,
    );
  }

  testWidgets(
      'sin sesión: invita a respaldar en la nube, no muestra la tarjeta de '
      'sesión', (tester) async {
    await pumpSettings(tester, session: const AuthSession.signedOut());

    expect(find.text('Respaldar en la nube'), findsOneWidget);
    expect(find.byType(SettingsSessionCard), findsNothing);
  });

  testWidgets('tocar "Respaldar en la nube" navega a Login', (tester) async {
    var loginOpened = false;
    await pumpSettings(
      tester,
      session: const AuthSession.signedOut(),
      onOpenLogin: () => loginOpened = true,
    );

    await tester.tap(find.text('Respaldar en la nube'));
    await tester.pump();

    expect(loginOpened, isTrue);
  });

  testWidgets(
      'con sesión: muestra la tarjeta de sesión con nombre y proveedor, no '
      'la invitación a respaldar', (tester) async {
    await pumpSettings(
      tester,
      session: const AuthSession.signedIn(user),
    );

    expect(find.byType(SettingsSessionCard), findsOneWidget);
    expect(find.text('Camila Agudelo'), findsOneWidget);
    expect(find.text('Sesión iniciada con Google'), findsOneWidget);
    expect(find.text('Respaldar en la nube'), findsNothing);
  });

  testWidgets(
      '"Cerrar sesión" no vive en Ajustes (se movió a "Más", ver auth.md)',
      (tester) async {
    await pumpSettings(tester, session: const AuthSession.signedIn(user));

    expect(find.text('Cerrar sesión'), findsNothing);
  });

  testWidgets(
      'HU-07: "Eliminar cuenta" siempre está disponible, en la zona '
      'destructiva al fondo', (tester) async {
    var deleteOpened = false;
    await pumpSettings(
      tester,
      session: const AuthSession.signedIn(user),
      onOpenDeleteAccount: () => deleteOpened = true,
    );

    expect(find.text('Eliminar cuenta'), findsOneWidget);
    await tester.ensureVisible(find.text('Eliminar cuenta'));
    await tester.pump();
    await tester.tap(find.text('Eliminar cuenta'));
    await tester.pump();

    expect(deleteOpened, isTrue);
  });

  testWidgets('las filas de Preferencias abren el placeholder "Próximamente"',
      (tester) async {
    final opened = <String>[];
    await pumpSettings(
      tester,
      session: const AuthSession.signedOut(),
      onOpenComingSoon: opened.add,
    );

    await tester.ensureVisible(find.text('Apariencia'));
    await tester.pump();
    await tester.tap(find.text('Apariencia'));
    await tester.pump();
    await tester.ensureVisible(find.text('Moneda'));
    await tester.pump();
    await tester.tap(find.text('Moneda'));
    await tester.pump();

    expect(opened, ['Apariencia', 'Moneda']);
  });
}
