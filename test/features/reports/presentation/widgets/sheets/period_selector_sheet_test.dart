import 'package:billetudo/core/l10n/gen/app_localizations.dart';
import 'package:billetudo/core/theme/app_theme.dart';
import 'package:billetudo/features/reports/presentation/models/reports_period_selection.dart';
import 'package:billetudo/features/reports/presentation/widgets/sheets/period_selector_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Non-golden coverage for [PeriodSelectorSheet]'s "custom range active"
/// state machine (`_customRangeStillActive`). The pixel-level "applied" look
/// (fill/border/check icon) is covered by
/// `period_selector_sheet_golden_test.dart`; this file asserts the *behavior*
/// that toggles it: opening with `kind == custom` starts "applied", and
/// interacting with the Mes/Año segmented control turns that off.
void main() {
  Future<void> pumpSheet(
    WidgetTester tester,
    ReportsPeriodSelection initial,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        locale: const Locale('es'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () =>
                  PeriodSelectorSheet.show(context, initial: initial),
              child: const Text('open'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.byType(ElevatedButton));
    await tester.pumpAndSettle();
  }

  final customSelection = ReportsPeriodSelection.custom(
    start: DateTime(2026, 3, 1),
    endExclusive: DateTime(2026, 9, 1),
  );

  testWidgets(
    'kind == custom: la fila de rango personalizado abre "aplicada", con el rango real',
    (tester) async {
      await pumpSheet(tester, customSelection);

      // Applied variant renders the real range caption as a second line
      // under the "Rango personalizado" label.
      expect(find.text('mar – ago 2026'), findsOneWidget);
    },
  );

  testWidgets(
    'tocar "Mes" apaga el estado aplicado del rango personalizado',
    (tester) async {
      await pumpSheet(tester, customSelection);

      expect(find.text('mar – ago 2026'), findsOneWidget);

      await tester.tap(find.text('Mes'));
      await tester.pumpAndSettle();

      // The applied variant's range caption disappears; the row falls back
      // to its plain link look (title only, no caption line).
      expect(find.text('mar – ago 2026'), findsNothing);
      expect(find.text('Rango personalizado'), findsOneWidget);
    },
  );

  testWidgets(
    'tocar "Año" también apaga el estado aplicado del rango personalizado',
    (tester) async {
      await pumpSheet(tester, customSelection);

      expect(find.text('mar – ago 2026'), findsOneWidget);

      await tester.tap(find.text('Año'));
      await tester.pumpAndSettle();

      expect(find.text('mar – ago 2026'), findsNothing);
      expect(find.text('Rango personalizado'), findsOneWidget);
    },
  );

  testWidgets(
    'kind == lastSixMonths (default): la fila de rango personalizado abre '
    '"aplicada" también, con el rango real de los últimos 6 meses',
    (tester) async {
      await pumpSheet(
        tester,
        ReportsPeriodSelection.lastSixMonths(now: DateTime(2025, 7, 15)),
      );

      // The default "últimos 6 meses" selection is treated as applied too
      // (not just an explicit `custom` selection): same caption row as the
      // custom-range case, showing the resolved range.
      expect(find.text('Rango personalizado'), findsOneWidget);
      expect(find.text('feb – jul 2025'), findsOneWidget);
    },
  );

  testWidgets(
    'kind == month: la fila de rango personalizado abre sin estado aplicado',
    (tester) async {
      await pumpSheet(tester, ReportsPeriodSelection.month(DateTime(2025, 7)));

      expect(find.text('Rango personalizado'), findsOneWidget);
      // No applied range caption for a `month`/`year` initial selection —
      // only `custom` and the `lastSixMonths` default start "applied".
      expect(find.textContaining(' – '), findsNothing);
    },
  );
}
