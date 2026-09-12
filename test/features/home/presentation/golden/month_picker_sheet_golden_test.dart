import 'package:billetudo/features/home/presentation/widgets/sheets/month_picker_sheet.dart';
import 'package:clock/clock.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../support/golden_helpers.dart';

/// The hero's month picker (HU-04, `k7kv4`/`iGwrg`): year stepper + 3×4 grid
/// of months. Covers the current year (selected month highlighted, future
/// months and the "next year" arrow disabled) and a past year navigated to
/// via the "previous year" arrow (no selection, no disabled months, both
/// arrows enabled).
void main() {
  final fixedNow = DateTime(2026, 8, 7, 12);
  final initialMonth = DateTime(2026, 6);

  setUpAll(() async {
    disableGoogleFontsRuntimeFetching();
    await loadMaterialIconsFont();
  });

  Future<void> openSheet(WidgetTester tester, Brightness brightness) async {
    setGoldenViewport(tester);
    await tester.pumpWidget(
      wrapForGolden(
        Builder(
          builder: (context) => ElevatedButton(
            onPressed: () => MonthPickerSheet.show(
              context,
              initialMonth: initialMonth,
              onMonthSelected: (_) {},
            ),
            child: const Text('open'),
          ),
        ),
        brightness: brightness,
      ),
    );
    await tester.tap(find.byType(ElevatedButton));
    await tester.pumpAndSettle();
  }

  for (final brightness in Brightness.values) {
    final suffix = brightness == Brightness.light ? 'light' : 'dark';

    testWidgets('month picker — año actual, mes seleccionado ($suffix)',
        (tester) async {
      await withClock(Clock.fixed(fixedNow), () async {
        await openSheet(tester, brightness);
        await expectLater(
          find.byType(MaterialApp),
          matchesGoldenFile(
              'goldens/month_picker_sheet_current_year_$suffix.png'),
        );
      });
    });

    testWidgets(
        'month picker — año anterior, sin selección ni deshabilitados ($suffix)',
        (tester) async {
      await withClock(Clock.fixed(fixedNow), () async {
        await openSheet(tester, brightness);
        await tester.tap(find.byTooltip('Año anterior'));
        await tester.pumpAndSettle();
        await expectLater(
          find.byType(MaterialApp),
          matchesGoldenFile('goldens/month_picker_sheet_past_year_$suffix.png'),
        );
      });
    });
  }
}
