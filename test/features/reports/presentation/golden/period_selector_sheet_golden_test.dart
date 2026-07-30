import 'package:billetudo/features/reports/presentation/models/reports_period_selection.dart';
import 'package:billetudo/features/reports/presentation/widgets/sheets/period_selector_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../support/golden_helpers.dart';

/// [PeriodSelectorSheet] is only speced in the `.pen` for its light base
/// case — see the widget's own doc comment: "no dark variant exists yet
/// either". Per this repo's golden playbook, a widget with no dark reference
/// in Pencil is captured light-only rather than inventing an unverified
/// dark; the gap is called out in the QA run's `manualChecks`/notes instead.
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
    String name,
  ) async {
    setGoldenViewport(tester);
    await tester.pumpWidget(
      wrapForGolden(
        Builder(
          builder: (context) => ElevatedButton(
            onPressed: () => PeriodSelectorSheet.show(context, initial: initial),
            child: const Text('open'),
          ),
        ),
        brightness: Brightness.light,
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
    // A `custom` initial selection is deliberately not covered here:
    // `_PeriodSelectorSheetState._cursor` falls back to `DateTime.now()` for
    // any kind other than month/year (see the widget's `late` initializer),
    // so a custom-kind golden would render a different month every day —
    // exactly the non-determinism goldens exist to avoid.
    await golden(
      tester,
      ReportsPeriodSelection.year(2025),
      'year_light',
    );
  });
}
