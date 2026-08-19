import 'package:billetudo/core/l10n/gen/app_localizations.dart';
import 'package:billetudo/core/theme/app_theme.dart';
import 'package:billetudo/features/goals/presentation/widgets/goal_recurring_contribution_entry_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// HU-16's entry point card (`hWrGw`/`D3Apm1`): geometry mirrors
/// `DebtConfigureInstallmentCard`, so this pins its copy and tap behaviour in
/// isolation — the goal detail page's own test covers where it's placed and
/// what it opens.
void main() {
  Future<void> pump(WidgetTester tester, VoidCallback onTap) => tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light(),
          locale: const Locale('es'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: GoalRecurringContributionEntryCard(onTap: onTap),
          ),
        ),
      );

  testWidgets('muestra el título y subtítulo esperados', (tester) async {
    await pump(tester, () {});

    expect(find.text('Configura un aporte recurrente'), findsOneWidget);
    expect(
      find.text('Automatiza tus aportes con un pago programado'),
      findsOneWidget,
    );
  });

  testWidgets('toca la card invoca onTap', (tester) async {
    var tapped = false;
    await pump(tester, () => tapped = true);

    await tester.tap(find.byType(GoalRecurringContributionEntryCard));
    await tester.pump();

    expect(tapped, isTrue);
  });
}
