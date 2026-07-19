import 'package:billetudo/features/scheduled_payments/presentation/widgets/sheets/delete_scheduled_payment_sheet.dart';
import 'package:billetudo/features/scheduled_payments/presentation/widgets/sheets/scheduled_payment_detail_actions_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../support/golden_helpers.dart';

/// Two of the detail screen's stateless sheets (criterion 12): the ⋮ menu
/// (grouping "Posponer" above a divider from "Editar"/"Eliminar" only when
/// the template can still be snoozed) and the delete confirmation (criterion
/// 12's copy: stops future generation, keeps generated history).
///
/// Pencil rows (`design-system/billetudo/pages/pagos-programados.md`):
/// `detail_actions_active` → `yHf9k` (menú ⋮ recurrente/transfer) ·
/// `detail_actions_inactive` → `nLkvf` (menú ⋮ sin Posponer), which the page
/// now reaches for a `once` template as well as for a tombstoned one (HU-07:
/// a one-off payment has no cadence to keep, so moving its date is editing
/// the template, not snoozing an occurrence). `sheet_delete` has no row of its own in the
/// table; it is the "sheet de confirmar-eliminar" the spec's Estado
/// paragraph lists.
void main() {
  setUpAll(() async {
    disableGoogleFontsRuntimeFetching();
    await loadMaterialIconsFont();
  });

  /// Opens [openSheet] through a real trigger button (scrim, drag handle and
  /// the `[28,28,0,0]` bottom sheet theme included) and captures the whole
  /// screen — mirrors `accounts/.../sheets_golden_test.dart`.
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

    testWidgets('acciones: plantilla activa, con Posponer y divisor ($suffix)',
        (tester) async {
      await golden(
        tester,
        (context) => ScheduledPaymentDetailActionsSheet.show(
          context,
          canSnooze: true,
          templateName: 'Netflix',
          onSnooze: () {},
          onEdit: () {},
          onDelete: () {},
        ),
        'detail_actions_active_$suffix',
        brightness: brightness,
      );
    });

    testWidgets(
        'acciones: plantilla inactiva, sin Posponer ni divisor ($suffix)',
        (tester) async {
      await golden(
        tester,
        (context) => ScheduledPaymentDetailActionsSheet.show(
          context,
          canSnooze: false,
          templateName: 'Netflix',
          onEdit: () {},
          onDelete: () {},
        ),
        'detail_actions_inactive_$suffix',
        brightness: brightness,
      );
    });

    testWidgets('eliminar plantilla: confirmación ($suffix)', (tester) async {
      await golden(
        tester,
        (context) =>
            DeleteScheduledPaymentSheet.show(context, onConfirm: () {}),
        'delete_$suffix',
        brightness: brightness,
      );
    });
  }
}
