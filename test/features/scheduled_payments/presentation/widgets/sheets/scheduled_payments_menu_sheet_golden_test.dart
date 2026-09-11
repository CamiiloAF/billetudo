import 'package:billetudo/features/scheduled_payments/presentation/widgets/sheets/scheduled_payments_menu_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../../support/golden_helpers.dart';

/// Pencil row (`design-system/billetudo/pages/minitutoriales.md` HU-03):
/// `Q2GpD` (menú `⋮` de Pagos programados, claro) → `AdVCt` (oscuro). The
/// sheet is stateless — one business state per theme.
void main() {
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
