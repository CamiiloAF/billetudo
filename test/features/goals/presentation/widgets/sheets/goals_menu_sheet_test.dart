import 'package:billetudo/core/l10n/gen/app_localizations.dart';
import 'package:billetudo/core/theme/app_theme.dart';
import 'package:billetudo/features/goals/presentation/widgets/sheets/goals_menu_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../../support/golden_helpers.dart';

/// Criterion 6 (`docs/requirements/16-minitutoriales.md`): Metas' overflow
/// menu gained a "Ver ayuda" row that reopens the HU-01 sheet — this was an
/// empty menu before minitutorials, so this test is the only place that
/// asserts the row exists and pops the right action at all.
///
/// Pencil row (`design-system/billetudo/pages/minitutoriales.md` HU-03):
/// `c9tyn1` (menú `⋮` de Metas, claro) → `V46Bbp` (oscuro). The sheet is
/// stateless — one business state per theme.
void main() {
  Future<void> pump(WidgetTester tester) => tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light(),
          locale: const Locale('es'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const Scaffold(body: GoalsMenuSheet()),
        ),
      );

  group('GoalsMenuSheet', () {
    testWidgets('offers "Ver ayuda"', (tester) async {
      await pump(tester);

      final context = tester.element(find.byType(GoalsMenuSheet));
      final l10n = AppLocalizations.of(context);

      expect(find.text(l10n.tutorialsMenuViewHelp), findsOneWidget);
      expect(find.text(l10n.goalsMenuViewHelpSubtitle), findsOneWidget);
      expect(find.text(l10n.goalsTitle), findsOneWidget);
    });

    testWidgets('tapping "Ver ayuda" pops GoalsMenuAction.viewHelp',
        (tester) async {
      GoalsMenuAction? result;
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light(),
          locale: const Locale('es'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: Builder(
              builder: (context) => TextButton(
                onPressed: () async {
                  result = await GoalsMenuSheet.show(context);
                },
                child: const Text('open'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      final context = tester.element(find.byType(GoalsMenuSheet));
      final l10n = AppLocalizations.of(context);
      await tester.tap(find.text(l10n.tutorialsMenuViewHelp));
      await tester.pumpAndSettle();

      expect(result, GoalsMenuAction.viewHelp);
    });
  });

  setUpAll(() async {
    disableGoogleFontsRuntimeFetching();
    await loadMaterialIconsFont();
  });

  for (final brightness in Brightness.values) {
    final suffix = brightness == Brightness.light ? 'light' : 'dark';

    testWidgets('golden: menú ⋮ de Metas ($suffix)', (tester) async {
      setGoldenViewport(tester);
      await tester.pumpWidget(
        wrapForGolden(
          Builder(
            builder: (context) => ElevatedButton(
              onPressed: () => GoalsMenuSheet.show(context),
              child: const Text('open'),
            ),
          ),
          brightness: brightness,
        ),
      );
      await tester.tap(find.byType(ElevatedButton));
      await tester.pumpAndSettle();
      await expectLater(
        find.byType(MaterialApp),
        matchesGoldenFile('goldens/goals_menu_sheet_$suffix.png'),
      );
    });
  }
}
