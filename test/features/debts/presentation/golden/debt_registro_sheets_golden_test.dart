import 'package:billetudo/core/widgets/bottom_sheet_base.dart';
import 'package:billetudo/features/debts/presentation/widgets/sheets/debt_initial_registro_sheet.dart';
import 'package:billetudo/features/debts/presentation/widgets/sheets/debt_update_registro_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../support/golden_helpers.dart';

/// The two stateless registro-inicial decision sheets (HU-01), both shown
/// through the app's own bottom-sheet chrome. Neither is destructive, so both
/// wear a brand `$primary`/`$primary-soft` icon — never `$expense`:
///   - `DebtInitialRegistroSheet` (`EXQfv`/`gcOj9`, item 2): "¿Quieres crear un
///     registro inicial para esta deuda?" with the "No, solo la deuda" /
///     "Sí, elegir cuenta" pair, shown right after creating a debt.
///   - `DebtUpdateRegistroSheet` (`hLe9z`/`G9qHX`, item 2b): "¿Actualizar también
///     el registro?" with a "de $X a $Y" delta message and the Cancelar /
///     confirm pair, shown when an edit changes the opening figure.
/// Each in light and dark.
void main() {
  setUpAll(() async {
    disableGoogleFontsRuntimeFetching();
    await loadMaterialIconsFont();
  });

  Future<void> golden(
    WidgetTester tester,
    Widget sheet,
    String name, {
    required Brightness brightness,
  }) async {
    setGoldenViewport(tester);
    await tester.pumpWidget(
      wrapForGolden(
        Builder(
          builder: (context) => ElevatedButton(
            onPressed: () => BottomSheetBase.show<void>(
              context,
              builder: (_) => sheet,
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
      matchesGoldenFile('goldens/debt_sheet_$name.png'),
    );
  }

  for (final brightness in Brightness.values) {
    final suffix = brightness == Brightness.light ? 'light' : 'dark';

    testWidgets('registro inicial: ¿crear registro? ($suffix)', (tester) async {
      await golden(
        tester,
        const DebtInitialRegistroSheet(),
        'initial_registro_$suffix',
        brightness: brightness,
      );
    });

    testWidgets('actualizar registro: de \$X a \$Y ($suffix)', (tester) async {
      await golden(
        tester,
        const DebtUpdateRegistroSheet(
          fromLabel: '\$4.200.000',
          toLabel: '\$4.500.000',
        ),
        'update_registro_$suffix',
        brightness: brightness,
      );
    });
  }
}
