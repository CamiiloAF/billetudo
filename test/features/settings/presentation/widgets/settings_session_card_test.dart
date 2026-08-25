import 'package:billetudo/core/l10n/gen/app_localizations.dart';
import 'package:billetudo/core/theme/app_theme.dart';
import 'package:billetudo/features/auth/domain/entities/auth_provider.dart';
import 'package:billetudo/features/auth/domain/entities/auth_session.dart';
import 'package:billetudo/features/auth/domain/entities/auth_user.dart';
import 'package:billetudo/features/settings/presentation/widgets/settings_session_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Future<void> pumpCard(WidgetTester tester, AuthSession session) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('es'),
        home: Builder(
          builder: (context) => Scaffold(
            body: SettingsSessionCard(
              session: session,
              l10n: AppLocalizations.of(context),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  const userWithEmail = AuthUser(
    id: 'google-1',
    displayName: 'Camila Agudelo',
    provider: AuthProvider.google,
    email: 'camila@gmail.com',
  );

  const userWithoutEmail = AuthUser(
    id: 'google-2',
    displayName: 'Camila Agudelo',
    provider: AuthProvider.google,
  );

  testWidgets('shows the email line when the user has one', (tester) async {
    await pumpCard(tester, const AuthSession.signedIn(userWithEmail));

    expect(find.text('camila@gmail.com'), findsOneWidget);
  });

  testWidgets(
    'omits the email line when the user has none',
    (tester) async {
      await pumpCard(tester, const AuthSession.signedIn(userWithoutEmail));

      expect(find.text('camila@gmail.com'), findsNothing);
      expect(find.text('Sesión iniciada con Google'), findsOneWidget);
    },
  );
}
