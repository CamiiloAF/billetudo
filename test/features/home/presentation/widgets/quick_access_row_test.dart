import 'package:billetudo/core/l10n/gen/app_localizations.dart';
import 'package:billetudo/features/home/domain/entities/quick_access_item.dart';
import 'package:billetudo/features/home/presentation/widgets/quick_access_row.dart';
import 'package:billetudo/features/home/presentation/widgets/quick_access_settings_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'pump_widget.dart';

void main() {
  Widget row({
    List<QuickAccessItem>? order,
    VoidCallback? onOpenScheduledPayments,
    VoidCallback? onOpenDebts,
    VoidCallback? onOpenReports,
    VoidCallback? onCustomize,
  }) =>
      QuickAccessRow(
        order: order ?? QuickAccessItem.defaultOrder,
        onOpenScheduledPayments: onOpenScheduledPayments ?? () {},
        onOpenDebts: onOpenDebts ?? () {},
        onOpenReports: onOpenReports ?? () {},
        onCustomize: onCustomize ?? () {},
      );

  AppLocalizations l10nOf(WidgetTester tester) =>
      AppLocalizations.of(tester.element(find.byType(QuickAccessRow)));

  testWidgets(
      'muestra el caption "Acceso rápido" y los 3 chips con sus '
      'labels (HU-05b)', (tester) async {
    await tester.pumpHomeWidget(row());
    final l10n = l10nOf(tester);

    expect(find.text(l10n.homeQuickAccessTitle), findsOneWidget);
    expect(find.byType(QuickAccessChip), findsNWidgets(3));
    expect(
      find.text(l10n.homeQuickAccessScheduledPayments),
      findsOneWidget,
    );
    expect(find.text(l10n.moreDebts), findsOneWidget);
    expect(find.text(l10n.moreReports), findsOneWidget);
  });

  testWidgets(
      'cierra la tira con la ruedita de configuración, que no es un chip más',
      (tester) async {
    await tester.pumpHomeWidget(row());

    // La ruedita existe pero NO cuenta como un cuarto destino: sigue habiendo
    // exactamente 3 chips. Si alguna vez se implementa como QuickAccessChip,
    // este test falla — es justo la confusión visual que se quiso evitar.
    expect(find.byType(QuickAccessSettingsButton), findsOneWidget);
    expect(find.byType(QuickAccessChip), findsNWidgets(3));
  });

  testWidgets(
      'la ruedita cabe en una pantalla de teléfono real: va anclada al borde '
      'derecho, fuera del scroll de los chips', (tester) async {
    // Regresión: cuando el botón vivía DENTRO del SingleChildScrollView,
    // los 3 chips medían ~507pt contra los 390pt de un teléfono y la ruedita
    // se renderizaba pasada la pantalla — un punto de entrada que nadie podía
    // ver ni tocar sin deslizar. Ningún golden lo detectó porque el widget
    // simplemente quedaba fuera del área capturada.
    const phoneWidth = 390.0;
    tester.view.physicalSize = const Size(phoneWidth, 844) * 3;
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    await tester.pumpHomeWidget(row());

    final gear = tester.getRect(find.byType(QuickAccessSettingsButton));
    expect(gear.right, lessThanOrEqualTo(phoneWidth));
    expect(gear.left, greaterThanOrEqualTo(0));
    // Y sigue leyéndose como el cierre de la tira, no como su comienzo.
    expect(
      gear.left,
      greaterThan(tester.getRect(find.byType(QuickAccessChip).first).right),
    );
  });

  testWidgets('la ruedita expone su nombre accesible por Tooltip (icon-only)',
      (tester) async {
    await tester.pumpHomeWidget(row());
    final l10n = l10nOf(tester);

    final tooltip = tester.widget<Tooltip>(
      find.descendant(
        of: find.byType(QuickAccessSettingsButton),
        matching: find.byType(Tooltip),
      ),
    );

    expect(tooltip.message, l10n.homeQuickAccessCustomize);
  });

  testWidgets('tocar la ruedita dispara onCustomize', (tester) async {
    var tapped = 0;
    await tester.pumpHomeWidget(row(onCustomize: () => tapped++));

    await tester.tap(find.byType(QuickAccessSettingsButton));
    await tester.pump();

    expect(tapped, 1);
  });

  testWidgets(
      'tocar el chip de pagos programados dispara onOpenScheduledPayments',
      (tester) async {
    var tapped = 0;
    await tester.pumpHomeWidget(
      row(onOpenScheduledPayments: () => tapped++),
    );
    final l10n = l10nOf(tester);

    await tester.tap(find.text(l10n.homeQuickAccessScheduledPayments));
    await tester.pump();

    expect(tapped, 1);
  });

  testWidgets('tocar el chip de deudas dispara onOpenDebts', (tester) async {
    var tapped = 0;
    await tester.pumpHomeWidget(row(onOpenDebts: () => tapped++));
    final l10n = l10nOf(tester);

    await tester.tap(find.text(l10n.moreDebts));
    await tester.pump();

    expect(tapped, 1);
  });

  testWidgets('tocar el chip de gráficas e informes dispara onOpenReports',
      (tester) async {
    var tapped = 0;
    await tester.pumpHomeWidget(row(onOpenReports: () => tapped++));
    final l10n = l10nOf(tester);

    await tester.tap(find.text(l10n.moreReports));
    await tester.pump();

    expect(tapped, 1);
  });

  testWidgets('tema oscuro: renderiza los 3 chips sin excepción (HU-11)',
      (tester) async {
    await tester.pumpHomeWidget(row(), brightness: Brightness.dark);

    expect(find.byType(QuickAccessChip), findsNWidgets(3));
    expect(tester.takeException(), isNull);
  });

  testWidgets(
      'con un orden distinto al por defecto, los chips se renderizan en '
      'ese orden (no en el orden fijo hardcodeado)', (tester) async {
    await tester.pumpHomeWidget(
      row(
        order: const [
          QuickAccessItem.reports,
          QuickAccessItem.debts,
          QuickAccessItem.scheduledPayments,
        ],
      ),
    );
    final l10n = l10nOf(tester);

    final reportsCenter = tester.getCenter(find.text(l10n.moreReports));
    final debtsCenter = tester.getCenter(find.text(l10n.moreDebts));
    final scheduledCenter = tester.getCenter(
      find.text(l10n.homeQuickAccessScheduledPayments),
    );

    expect(reportsCenter.dx, lessThan(debtsCenter.dx));
    expect(debtsCenter.dx, lessThan(scheduledCenter.dx));
  });
}
