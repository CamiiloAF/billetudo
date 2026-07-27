import 'package:billetudo/features/settings/presentation/widgets/sheets/envelope_info_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../support/golden_helpers.dart';

/// The "¿Qué es el modo sobres?" sheet.
///
/// Pencil row (`design-system/billetudo/pages/presupuestos.md`):
/// `envelope_info` → `eBwb0` / `gAetG` (Sheet — info "¿Qué es el modo
/// sobres?"). Everything is left-aligned there: icon-wrap, title, body,
/// bullets and reassurance.
///
/// Two business states. `off` is the designed one (both buttons: the primary
/// "Activar modo sobres" plus "Entendido"); `on` is **not** in the `.pen` —
/// with the mode already active the activation call to action would be
/// nonsense, so it is dropped and only "Entendido" remains.
void main() {
  setUpAll(() async {
    disableGoogleFontsRuntimeFetching();
    await loadMaterialIconsFont();
  });

  Future<void> golden(
    WidgetTester tester,
    String name, {
    required bool envelopeEnabled,
    required Brightness brightness,
  }) async {
    setGoldenViewport(tester);
    await tester.pumpWidget(
      wrapForGolden(
        Builder(
          builder: (context) => ElevatedButton(
            onPressed: () => EnvelopeInfoSheet.show(
              context,
              envelopeEnabled: envelopeEnabled,
            ),
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

    testWidgets('info modo sobres: apagado, con CTA ($suffix)', (tester) async {
      await golden(
        tester,
        'envelope_info_off_$suffix',
        envelopeEnabled: false,
        brightness: brightness,
      );
    });

    testWidgets('info modo sobres: ya activo, sin CTA ($suffix)',
        (tester) async {
      await golden(
        tester,
        'envelope_info_on_$suffix',
        envelopeEnabled: true,
        brightness: brightness,
      );
    });
  }
}
