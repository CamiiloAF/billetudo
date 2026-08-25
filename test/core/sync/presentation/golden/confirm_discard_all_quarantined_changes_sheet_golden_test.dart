import 'package:billetudo/core/sync/presentation/widgets/sheets/confirm_discard_all_quarantined_changes_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../support/golden_helpers.dart';

/// "Sync Sheet — Confirmar Descartar Todo" (`EtwDY`). Same destructive
/// pattern as `ConfirmDiscardQuarantinedChangeSheet` (`qZvmL`) — `$expense`
/// icon and button — but pluralized around the count: singular (1 pendiente)
/// and plural (89 pendientes) render different copy in title and message.
void main() {
  setUpAll(() async {
    disableGoogleFontsRuntimeFetching();
    await loadMaterialIconsFont();
  });

  Future<void> golden(
    WidgetTester tester,
    String name, {
    required Brightness brightness,
    required int count,
  }) async {
    setGoldenViewport(tester);
    await tester.pumpWidget(
      wrapForGolden(
        Builder(
          builder: (context) => ElevatedButton(
            onPressed: () => ConfirmDiscardAllQuarantinedChangesSheet.show(
              context,
              count: count,
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
      matchesGoldenFile(
        'goldens/confirm_discard_all_quarantined_changes_sheet_$name.png',
      ),
    );
  }

  for (final brightness in Brightness.values) {
    final suffix = brightness == Brightness.light ? 'light' : 'dark';

    testWidgets('confirmar descartar todo — plural ($suffix)',
        (tester) async {
      await golden(tester, suffix, brightness: brightness, count: 89);
    });

    testWidgets('confirmar descartar todo — singular ($suffix)',
        (tester) async {
      await golden(
        tester,
        'singular_$suffix',
        brightness: brightness,
        count: 1,
      );
    });
  }
}
