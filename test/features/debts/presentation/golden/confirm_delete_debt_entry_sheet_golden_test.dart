import 'package:billetudo/core/widgets/bottom_sheet_base.dart';
import 'package:billetudo/features/debts/presentation/widgets/sheets/confirm_delete_debt_entry_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../support/golden_helpers.dart';

/// Fix B (`ConfirmDeleteDebtEntrySheet`): confirms deleting a single
/// solo-deuda movement from `DebtMovementDetailSheet`'s "Eliminar" action.
/// The sheet takes no parameters — its copy ("¿Eliminar este movimiento?")
/// does not vary by `DebtEntryKind` (abono, desembolso, interés or ajuste all
/// share it, per `ConfirmDeleteDebtEntrySheet`'s source, which stores no
/// entry data at all) — so there is exactly one business state, in light and
/// dark. Same destructive pattern as `ConfirmDeleteDebtSheet` (`$expense`,
/// never brand violet), scoped to one movement instead of a whole debt.
void main() {
  setUpAll(() async {
    disableGoogleFontsRuntimeFetching();
    await loadMaterialIconsFont();
  });

  Future<void> golden(
    WidgetTester tester, {
    required Brightness brightness,
  }) async {
    setGoldenViewport(tester);
    await tester.pumpWidget(
      wrapForGolden(
        Builder(
          builder: (context) => ElevatedButton(
            onPressed: () => BottomSheetBase.show<bool>(
              context,
              builder: (_) => const ConfirmDeleteDebtEntrySheet(),
            ),
            child: const Text('open'),
          ),
        ),
        brightness: brightness,
      ),
    );
    await tester.tap(find.byType(ElevatedButton));
    await tester.pumpAndSettle();
    final suffix = brightness == Brightness.light ? 'light' : 'dark';
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/confirm_delete_debt_entry_sheet_$suffix.png'),
    );
  }

  for (final brightness in Brightness.values) {
    final suffix = brightness == Brightness.light ? 'light' : 'dark';

    testWidgets('confirmar eliminar movimiento ($suffix)', (tester) async {
      await golden(tester, brightness: brightness);
    });
  }
}
