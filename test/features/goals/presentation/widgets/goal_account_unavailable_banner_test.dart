import 'package:billetudo/core/l10n/gen/app_localizations.dart';
import 'package:billetudo/core/theme/app_theme.dart';
import 'package:billetudo/features/goals/presentation/widgets/goal_account_unavailable_banner.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Future<void> pump(WidgetTester tester, VoidCallback onLinkAnother) =>
      tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light(),
          locale: const Locale('es'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: GoalAccountUnavailableBanner(onLinkAnother: onLinkAnother),
          ),
        ),
      );

  testWidgets('muestra el aviso y el link "Vincular otra cuenta"',
      (tester) async {
    await pump(tester, () {});

    expect(
      find.text(
        'La cuenta que tenías vinculada ya no está disponible. Tu historial '
        'sigue completo y esta meta pasa a avance manual.',
      ),
      findsOneWidget,
    );
    expect(find.text('Vincular otra cuenta'), findsOneWidget);
  });

  testWidgets('tocar la fila llama a onLinkAnother', (tester) async {
    var tapped = false;
    await pump(tester, () => tapped = true);

    await tester.tap(find.byType(GoalAccountUnavailableBanner));
    expect(tapped, isTrue);
  });
}
