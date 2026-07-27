import 'package:billetudo/core/widgets/bottom_sheet_base.dart';
import 'package:billetudo/features/debts/presentation/widgets/sheets/confirm_delete_debt_sheet.dart';
import 'package:billetudo/features/debts/presentation/widgets/sheets/debt_account_picker_sheet.dart';
import 'package:billetudo/features/debts/presentation/widgets/sheets/debt_currency_picker_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../support/golden_helpers.dart';
import '../../../accounts/account_fixtures.dart';

/// The stateless (cubit-less) Deudas sheets, each shown through the app's own
/// bottom-sheet chrome:
///   - `ConfirmDeleteDebtSheet` (HU-05): reversible-trash copy, the destructive
///     button in `$expense` (never brand violet).
///   - `DebtCurrencyPickerSheet` (HU-01): the short COP/USD set, COP selected.
///   - `DebtAccountPickerSheet` (HU-02): single-select account rows reusing the
///     accounts feature's row.
/// Each in light and dark.
void main() {
  setUpAll(() async {
    disableGoogleFontsRuntimeFetching();
    await loadMaterialIconsFont();
  });

  final accounts = [
    buildAccountWithBalance(
      account: buildAccount(id: 'a1', name: 'Bancolombia'),
      balanceMinor: 3450000,
    ),
    buildAccountWithBalance(
      account: buildAccount(id: 'a2', name: 'Efectivo'),
      balanceMinor: 120000,
    ),
  ];

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

    testWidgets('confirmar eliminar deuda ($suffix)', (tester) async {
      await golden(
        tester,
        const ConfirmDeleteDebtSheet(),
        'confirm_delete_$suffix',
        brightness: brightness,
      );
    });

    testWidgets('picker de moneda ($suffix)', (tester) async {
      await golden(
        tester,
        const DebtCurrencyPickerSheet(selected: 'COP'),
        'currency_picker_$suffix',
        brightness: brightness,
      );
    });

    testWidgets('picker de cuenta ($suffix)', (tester) async {
      await golden(
        tester,
        DebtAccountPickerSheet(accounts: accounts, selectedId: 'a1'),
        'account_picker_$suffix',
        brightness: brightness,
      );
    });
  }
}
