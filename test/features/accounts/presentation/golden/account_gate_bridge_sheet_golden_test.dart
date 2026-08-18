import 'package:billetudo/core/l10n/gen/app_localizations.dart';
import 'package:billetudo/core/widgets/bottom_sheet_base.dart';
import 'package:billetudo/features/accounts/presentation/widgets/account_gate_bridge_sheet.dart';
import 'package:billetudo/features/accounts/presentation/widgets/account_gate_copy.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../support/golden_helpers.dart';

/// Golden coverage for the account gate's shared "puente, no muro" sheet
/// (`docs/requirements/fase-1/15-gate-cuenta.md` HU-01, `design-system/billetudo/
/// pages/gate-cuenta.md` Variante B): one case per [AccountGateSurface],
/// since each carries its own icon and copy (`Zjsfz`/`XYfSq`/`goGwA`/
/// `G0mfgY`/`K6bGhq`/`xU4uz`/`oHAVJ`) — and, for transferencia, both the
/// "0 cuentas" and "segunda cuenta" copy, since those are the same surface
/// with genuinely different content, not a repeat.
void main() {
  setUpAll(() async {
    disableGoogleFontsRuntimeFetching();
    await loadMaterialIconsFont();
  });

  Future<void> golden(
    WidgetTester tester,
    String name, {
    required Brightness brightness,
    required AccountGateSurface surface,
    required int currentCount,
  }) async {
    setGoldenViewport(tester);
    await tester.pumpWidget(
      wrapForGolden(
        Builder(
          builder: (context) => ElevatedButton(
            onPressed: () => BottomSheetBase.show<bool>(
              context,
              builder: (context) => AccountGateBridgeSheet(
                copy: AccountGateCopy.resolve(
                  AppLocalizations.of(context),
                  surface,
                  currentCount: currentCount,
                ),
              ),
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
      matchesGoldenFile('goldens/account_gate_bridge_sheet_$name.png'),
    );
  }

  for (final brightness in Brightness.values) {
    final suffix = brightness == Brightness.light ? 'light' : 'dark';

    testWidgets('registrar movimiento, Zjsfz ($suffix)', (tester) async {
      await golden(
        tester,
        'movement_$suffix',
        brightness: brightness,
        surface: AccountGateSurface.movement,
        currentCount: 0,
      );
    });

    testWidgets('transferencia con 0 cuentas, XYfSq ($suffix)',
        (tester) async {
      await golden(
        tester,
        'transfer_zero_$suffix',
        brightness: brightness,
        surface: AccountGateSurface.transfer,
        currentCount: 0,
      );
    });

    testWidgets('transferencia con 1 cuenta (segunda cuenta), goGwA ($suffix)',
        (tester) async {
      await golden(
        tester,
        'transfer_one_$suffix',
        brightness: brightness,
        surface: AccountGateSurface.transfer,
        currentCount: 1,
      );
    });

    testWidgets('pago programado, G0mfgY ($suffix)', (tester) async {
      await golden(
        tester,
        'scheduled_payment_$suffix',
        brightness: brightness,
        surface: AccountGateSurface.scheduledPayment,
        currentCount: 0,
      );
    });

    testWidgets('deuda con caja, K6bGhq ($suffix)', (tester) async {
      await golden(
        tester,
        'debt_cash_$suffix',
        brightness: brightness,
        surface: AccountGateSurface.debtCash,
        currentCount: 0,
      );
    });

    testWidgets('meta con movimiento, xU4uz ($suffix)', (tester) async {
      await golden(
        tester,
        'goal_movement_$suffix',
        brightness: brightness,
        surface: AccountGateSurface.goalMovement,
        currentCount: 0,
      );
    });

    testWidgets('enlazar movimiento existente, oHAVJ ($suffix)',
        (tester) async {
      await golden(
        tester,
        'link_movement_$suffix',
        brightness: brightness,
        surface: AccountGateSurface.linkMovement,
        currentCount: 0,
      );
    });
  }
}
