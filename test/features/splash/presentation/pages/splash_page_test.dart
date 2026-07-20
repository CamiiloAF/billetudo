import 'package:billetudo/core/l10n/gen/app_localizations.dart';
import 'package:billetudo/core/theme/app_theme.dart';
import 'package:billetudo/core/widgets/brand_wordmark.dart';
import 'package:billetudo/features/splash/presentation/pages/splash_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Future<void> pumpSplash(WidgetTester tester) => tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light(),
          locale: const Locale('es'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const SplashPage(),
        ),
      );

  testWidgets(
      'muestra el wordmark, un spinner indeterminado (no una barra de '
      'progreso) y el caption de carga', (tester) async {
    await pumpSplash(tester);

    expect(find.byType(BrandWordmark), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.byType(LinearProgressIndicator), findsNothing);
    expect(find.text('Cargando tus finanzas...'), findsOneWidget);
  });
}
