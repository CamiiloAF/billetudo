import 'package:billetudo/features/home/presentation/widgets/sheets/month_picker_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

import '../../../../support/golden_helpers.dart';

void main() {
  setUpAll(() async {
    await initializeDateFormatting();
    disableGoogleFontsRuntimeFetching();
    await loadMaterialIconsFont();
  });

  /// Opens [openSheet] through a real trigger button (mirrors how a sheet
  /// actually reaches the screen — scrim, drag handle and the `[28,28,0,0]`
  /// bottom sheet theme included) and captures the whole screen.
  Future<void> golden(
    WidgetTester tester,
    Future<void> Function(BuildContext context) openSheet,
    String name, {
    required Brightness brightness,
  }) async {
    setGoldenViewport(tester);
    await tester.pumpWidget(
      wrapForGolden(
        Builder(
          builder: (context) => ElevatedButton(
            onPressed: () => openSheet(context),
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
      matchesGoldenFile('goldens/sheet_$name.png'),
    );
  }

  for (final brightness in Brightness.values) {
    final suffix = brightness == Brightness.light ? 'light' : 'dark';

    testWidgets('month picker, current month selected (HU-04) ($suffix)',
        (tester) async {
      await golden(
        tester,
        (context) => MonthPickerSheet.show(
          context,
          selected: DateTime(2026, 7),
          currentMonth: DateTime(2026, 7),
        ),
        'month_picker_current_$suffix',
        brightness: brightness,
      );
    });

    testWidgets(
        'month picker, past year — future months no longer disabled '
        '($suffix)', (tester) async {
      await golden(
        tester,
        (context) => MonthPickerSheet.show(
          context,
          selected: DateTime(2025, 3),
          currentMonth: DateTime(2026, 7),
        ),
        'month_picker_past_year_$suffix',
        brightness: brightness,
      );
    });
  }
}
