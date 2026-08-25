import 'package:billetudo/core/sync/presentation/widgets/sheets/confirm_discard_quarantined_change_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../support/golden_helpers.dart';

/// "Sync Sheet — Confirmar Descartar" (`qZvmL`). Same destructive pattern as
/// `ConfirmDeleteAccountSheet` (`$expense` icon + button), reused verbatim
/// for both entry points (`PendingChangeDetailSheet`'s "Descartar" link and
/// the full list's row footer once that surface wires it up).
void main() {
  setUpAll(() async {
    disableGoogleFontsRuntimeFetching();
    await loadMaterialIconsFont();
  });

  Future<void> golden(
    WidgetTester tester,
    String name, {
    required Brightness brightness,
  }) async {
    setGoldenViewport(tester);
    await tester.pumpWidget(
      wrapForGolden(
        Builder(
          builder: (context) => ElevatedButton(
            onPressed: () => ConfirmDiscardQuarantinedChangeSheet.show(context),
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
      matchesGoldenFile(
          'goldens/confirm_discard_quarantined_change_sheet_$name.png'),
    );
  }

  for (final brightness in Brightness.values) {
    final suffix = brightness == Brightness.light ? 'light' : 'dark';

    testWidgets('confirmar descartar ($suffix)', (tester) async {
      await golden(tester, suffix, brightness: brightness);
    });
  }
}
