import 'package:billetudo/core/l10n/gen/app_localizations.dart';
import 'package:billetudo/core/theme/app_theme.dart';
import 'package:billetudo/features/scheduled_payments/presentation/widgets/sheets/scheduled_payments_menu_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../../support/golden_helpers.dart';

/// Criterion 6 (`docs/requirements/fase-1/16-minitutoriales.md`): Pagos programados'
/// overflow menu gained a "Ver ayuda" row that reopens the HU-01 sheet — this
/// tab root had an empty action spacer before minitutorials, so this test is
/// the only place that asserts the row exists and pops the right action at
/// all.
///
/// Pencil row (`design-system/billetudo/pages/minitutoriales.md` HU-03):
/// `Q2GpD` (menú `⋮` de Pagos programados, claro) → `AdVCt` (oscuro). The
/// sheet is stateless — one business state per theme.
void main() {
  Future<void> pump(WidgetTester tester) => tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light(),
          locale: const Locale('es'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const Scaffold(body: ScheduledPaymentsMenuSheet()),
        ),
      );

  group('ScheduledPaymentsMenuSheet', () {
    testWidgets('offers "Ver ayuda"', (tester) async {
      await pump(tester);

      final context = tester.element(find.byType(ScheduledPaymentsMenuSheet));
      final l10n = AppLocalizations.of(context);

      expect(find.text(l10n.tutorialsMenuViewHelp), findsOneWidget);
      expect(find.text(l10n.scheduledPaymentsMenuViewHelpSubtitle), findsOneWidget);
      expect(find.text(l10n.scheduledPaymentsTitle), findsOneWidget);
    });

    testWidgets('tapping "Ver ayuda" pops ScheduledPaymentsMenuAction.viewHelp',
        (tester) async {
      ScheduledPaymentsMenuAction? result;
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
                  result = await ScheduledPaymentsMenuSheet.show(context);
                },
                child: const Text('open'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      final context = tester.element(find.byType(ScheduledPaymentsMenuSheet));
      final l10n = AppLocalizations.of(context);
      await tester.tap(find.text(l10n.tutorialsMenuViewHelp));
      await tester.pumpAndSettle();

      expect(result, ScheduledPaymentsMenuAction.viewHelp);
    });
  });

  setUpAll(() async {
    disableGoogleFontsRuntimeFetching();
    await loadMaterialIconsFont();
  });

  for (final brightness in Brightness.values) {
    final suffix = brightness == Brightness.light ? 'light' : 'dark';

    testWidgets('golden: menú ⋮ de Pagos programados ($suffix)',
        (tester) async {
      setGoldenViewport(tester);
      await tester.pumpWidget(
        wrapForGolden(
          Builder(
            builder: (context) => ElevatedButton(
              onPressed: () => ScheduledPaymentsMenuSheet.show(context),
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
        matchesGoldenFile('goldens/scheduled_payments_menu_sheet_$suffix.png'),
      );
    });
  }
}
