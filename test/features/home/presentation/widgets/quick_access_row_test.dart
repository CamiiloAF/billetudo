import 'package:billetudo/core/l10n/gen/app_localizations.dart';
import 'package:billetudo/features/home/domain/entities/quick_access_item.dart';
import 'package:billetudo/features/home/presentation/widgets/quick_access_chip_with_badge.dart';
import 'package:billetudo/features/home/presentation/widgets/quick_access_row.dart';
import 'package:billetudo/features/home/presentation/widgets/quick_access_settings_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'pump_widget.dart';

void main() {
  Widget row({
    List<QuickAccessItem>? order,
    int pendingScheduledCount = 0,
    VoidCallback? onOpenScheduledPayments,
    VoidCallback? onOpenAccounts,
    VoidCallback? onOpenDebts,
    VoidCallback? onOpenReports,
    VoidCallback? onOpenGoals,
    VoidCallback? onCustomize,
  }) =>
      QuickAccessRow(
        order: order ?? QuickAccessItem.defaultOrder,
        pendingScheduledCount: pendingScheduledCount,
        onOpenScheduledPayments: onOpenScheduledPayments ?? () {},
        onOpenAccounts: onOpenAccounts ?? () {},
        onOpenDebts: onOpenDebts ?? () {},
        onOpenReports: onOpenReports ?? () {},
        onOpenGoals: onOpenGoals ?? () {},
        onCustomize: onCustomize ?? () {},
      );

  AppLocalizations l10nOf(WidgetTester tester) =>
      AppLocalizations.of(tester.element(find.byType(QuickAccessRow)));

  testWidgets(
      'muestra el caption "Acceso rápido" y los 5 chips con sus '
      'labels (criterio 13)', (tester) async {
    await tester.pumpHomeWidget(row());
    final l10n = l10nOf(tester);

    expect(find.text(l10n.homeQuickAccessTitle), findsOneWidget);
    expect(find.byType(QuickAccessChip), findsNWidgets(5));
    expect(
      find.text(l10n.homeQuickAccessScheduledPayments),
      findsOneWidget,
    );
    expect(find.text(l10n.accountsTitle), findsOneWidget);
    expect(find.text(l10n.moreDebts), findsOneWidget);
    expect(find.text(l10n.moreReports), findsOneWidget);
    expect(find.text(l10n.navGoals), findsOneWidget);
  });

  testWidgets(
      'con ocurrencias pendientes, el chip de pagos programados lleva badge '
      'con el contador (criterio 13)', (tester) async {
    await tester.pumpHomeWidget(row(pendingScheduledCount: 2));

    expect(find.byType(QuickAccessChipWithBadge), findsOneWidget);
    expect(find.text('2'), findsOneWidget);
    // Con badge, ya no es una instancia del chip base — 4 quedan sin badge.
    expect(find.byType(QuickAccessChip), findsNWidgets(4));
  });

  testWidgets(
      'con más de 9 ocurrencias pendientes, el badge corta en "9+" '
      '(criterio 13)', (tester) async {
    await tester.pumpHomeWidget(row(pendingScheduledCount: 15));

    expect(find.text('9+'), findsOneWidget);
  });

  testWidgets(
      'sin ocurrencias pendientes, el chip de pagos programados no lleva '
      'badge (criterio 13)', (tester) async {
    await tester.pumpHomeWidget(row());

    expect(find.byType(QuickAccessChipWithBadge), findsNothing);
    expect(find.byType(QuickAccessChip), findsNWidgets(5));
  });

  testWidgets(
      'cierra la tira con la ruedita de configuración, que no es un chip más',
      (tester) async {
    await tester.pumpHomeWidget(row());

    // La ruedita existe pero NO cuenta como un sexto destino: sigue habiendo
    // exactamente 5 chips. Si alguna vez se implementa como QuickAccessChip,
    // este test falla — es justo la confusión visual que se quiso evitar.
    expect(find.byType(QuickAccessSettingsButton), findsOneWidget);
    expect(find.byType(QuickAccessChip), findsNWidgets(5));
  });

  testWidgets(
      'la ruedita es el 6.º y último ítem del scroll horizontal, después de '
      'los 5 chips de categoría (nodo Pencil u4f7l)', (tester) async {
    await tester.pumpHomeWidget(row());

    final gear = tester.getRect(find.byType(QuickAccessSettingsButton));
    final lastChip = tester.getRect(find.byType(QuickAccessChip).last);

    // Sigue leyéndose como el cierre de la tira, no como su comienzo — y
    // ahora vive DENTRO del mismo scroll horizontal que los chips, ya no
    // fijo aparte fuera de él.
    expect(gear.left, greaterThan(lastChip.right));
    expect(
      find.descendant(
        of: find.byType(SingleChildScrollView),
        matching: find.byType(QuickAccessSettingsButton),
      ),
      findsOneWidget,
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

  testWidgets('tocar el chip de cuentas dispara onOpenAccounts',
      (tester) async {
    var tapped = 0;
    await tester.pumpHomeWidget(row(onOpenAccounts: () => tapped++));
    final l10n = l10nOf(tester);

    await tester.tap(find.text(l10n.accountsTitle));
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

  testWidgets('tocar el chip de metas dispara onOpenGoals', (tester) async {
    var tapped = 0;
    await tester.pumpHomeWidget(row(onOpenGoals: () => tapped++));
    final l10n = l10nOf(tester);

    await tester.tap(find.text(l10n.navGoals));
    await tester.pump();

    expect(tapped, 1);
  });

  testWidgets('tema oscuro: renderiza los 5 chips sin excepción (HU-11)',
      (tester) async {
    await tester.pumpHomeWidget(row(), brightness: Brightness.dark);

    expect(find.byType(QuickAccessChip), findsNWidgets(5));
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
          QuickAccessItem.accounts,
          QuickAccessItem.goals,
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
