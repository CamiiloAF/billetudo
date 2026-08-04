import 'package:billetudo/features/reports/presentation/models/reports_period_selection.dart';
import 'package:billetudo/features/reports/presentation/widgets/sheets/period_selector_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../support/golden_helpers.dart';

/// [PeriodSelectorSheet]'s base case (`Sy92N`) is only speced in the `.pen`
/// for light — see the widget's own doc comment: "no dark variant exists yet
/// either". Per this repo's golden playbook, a widget with no dark reference
/// in Pencil is captured light-only rather than inventing an unverified dark;
/// the gap is called out in the QA run's `manualChecks`/notes instead.
///
/// The "custom range active" state (`c3gyor` light / `XkFWg` dark, see
/// `design-system/billetudo/pages/graficas.md`, "Sheets") IS fully speced in
/// both themes, so it's captured light and dark below.
void main() {
  setUpAll(() async {
    disableGoogleFontsRuntimeFetching();
    await loadMaterialIconsFont();
  });

  /// Opens the sheet through a real trigger button, same choreography as
  /// `test/features/accounts/presentation/golden/sheets_golden_test.dart`.
  Future<void> golden(
    WidgetTester tester,
    ReportsPeriodSelection initial,
    String name, {
    Brightness brightness = Brightness.light,
  }) async {
    setGoldenViewport(tester);
    await tester.pumpWidget(
      wrapForGolden(
        Builder(
          builder: (context) => ElevatedButton(
            onPressed: () => PeriodSelectorSheet.show(context, initial: initial),
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
      matchesGoldenFile('goldens/sheet_period_selector_$name.png'),
    );
  }

  testWidgets('month granularity, default range (light)', (tester) async {
    await golden(
      tester,
      ReportsPeriodSelection.lastSixMonths(now: DateTime(2025, 7, 15)),
      'month_light',
    );
  });

  testWidgets('year granularity (light)', (tester) async {
    await golden(
      tester,
      ReportsPeriodSelection.year(2025),
      'year_light',
    );
  });

  for (final brightness in Brightness.values) {
    final suffix = brightness == Brightness.light ? 'light' : 'dark';
    testWidgets('custom range active ($suffix)', (tester) async {
      await golden(
        tester,
        ReportsPeriodSelection.custom(
          start: DateTime(2026, 3, 1),
          endExclusive: DateTime(2026, 9, 1),
        ),
        'custom_$suffix',
        brightness: brightness,
      );
    });
  }
}
