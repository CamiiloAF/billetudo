import 'package:billetudo/core/l10n/gen/app_localizations.dart';
import 'package:billetudo/core/theme/app_theme.dart';
import 'package:billetudo/core/widgets/brand_wordmark.dart';
import 'package:billetudo/features/splash/presentation/pages/splash_page.dart';
import 'package:billetudo/features/splash/presentation/widgets/brand_block.dart';
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
      'muestra el icono de marca, el wordmark, un spinner indeterminado '
      '(no una barra de progreso) y el caption de carga', (tester) async {
    await pumpSplash(tester);
    // Settle the one-shot entrance animation (the spinner itself is
    // indeterminate/repeating, but `pumpAndSettle` only needs the finite
    // fade/scale animations to finish, since `CircularProgressIndicator`'s
    // repeating controller does not block it).
    await tester.pump(const Duration(milliseconds: 700));

    expect(find.byType(BrandBlock), findsOneWidget);
    expect(find.byType(BrandWordmark), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.byType(LinearProgressIndicator), findsNothing);
    expect(find.text('Cargando tus finanzas...'), findsOneWidget);
  });
}
