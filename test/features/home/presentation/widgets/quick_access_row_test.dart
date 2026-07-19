import 'package:billetudo/core/l10n/gen/app_localizations.dart';
import 'package:billetudo/features/home/presentation/widgets/quick_access_row.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'pump_widget.dart';

void main() {
  Widget row({
    VoidCallback? onOpenAccounts,
    VoidCallback? onOpenScheduledPayments,
    VoidCallback? onOpenDebts,
    VoidCallback? onOpenReports,
  }) =>
      QuickAccessRow(
        onOpenAccounts: onOpenAccounts ?? () {},
        onOpenScheduledPayments: onOpenScheduledPayments ?? () {},
        onOpenDebts: onOpenDebts ?? () {},
        onOpenReports: onOpenReports ?? () {},
      );

  AppLocalizations l10nOf(WidgetTester tester) =>
      AppLocalizations.of(tester.element(find.byType(QuickAccessRow)));

  testWidgets('muestra el caption "Acceso rápido" y los 4 chips con sus '
      'labels (HU-05b)', (tester) async {
    await tester.pumpHomeWidget(row());
    final l10n = l10nOf(tester);

    expect(find.text(l10n.homeQuickAccessTitle), findsOneWidget);
    expect(find.byType(QuickAccessChip), findsNWidgets(4));
    expect(find.text(l10n.accountsTitle), findsOneWidget);
    expect(
      find.text(l10n.homeQuickAccessScheduledPayments),
      findsOneWidget,
    );
    expect(find.text(l10n.moreDebts), findsOneWidget);
    expect(find.text(l10n.moreReports), findsOneWidget);
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

  testWidgets('tema oscuro: renderiza los 4 chips sin excepción (HU-11)',
      (tester) async {
    await tester.pumpHomeWidget(row(), brightness: Brightness.dark);

    expect(find.byType(QuickAccessChip), findsNWidgets(4));
    expect(tester.takeException(), isNull);
  });
}
