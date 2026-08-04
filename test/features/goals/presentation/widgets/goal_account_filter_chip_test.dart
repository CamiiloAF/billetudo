import 'package:billetudo/core/l10n/gen/app_localizations.dart';
import 'package:billetudo/core/theme/app_theme.dart';
import 'package:billetudo/features/goals/presentation/widgets/goal_account_filter_chip.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

void main() {
  Future<void> pump(WidgetTester tester, VoidCallback onClear) =>
      tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light(),
          locale: const Locale('es'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: GoalAccountFilterChip(
              accountName: 'Ahorros Bancolombia',
              onClear: onClear,
            ),
          ),
        ),
      );

  testWidgets('muestra "Metas en <cuenta>"', (tester) async {
    await pump(tester, () {});

    expect(find.text('Metas en Ahorros Bancolombia'), findsOneWidget);
  });

  testWidgets('tocar la X llama a onClear', (tester) async {
    var cleared = false;
    await pump(tester, () => cleared = true);

    await tester.tap(find.byIcon(LucideIcons.x).hitTestable().first);
    expect(cleared, isTrue);
  });
}
