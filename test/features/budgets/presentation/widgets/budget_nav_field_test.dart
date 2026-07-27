import 'package:billetudo/features/budgets/presentation/widgets/budget_nav_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../accounts/presentation/widgets/pump_widget.dart';

/// `a3gGPM/dRD7G`, `cb5On`, `lEQXw`, `kfLey`: the `Form Field` component with
/// the outer label off, the value read inline as "Etiqueta: valor" and a
/// `chevron-right` (navigation to a sheet), never `chevron-down`.
void main() {
  Future<void> pump(WidgetTester tester, Widget child) =>
      tester.pumpAppWidget(SizedBox(width: 350, child: child));

  testWidgets('reads the label and the value inline, with a chevron-right',
      (tester) async {
    await pump(
      tester,
      BudgetNavField(
        label: 'Cuentas',
        value: 'Todas las cuentas',
        icon: LucideIcons.wallet,
        onTap: () {},
      ),
    );

    expect(find.text('Cuentas: Todas las cuentas'), findsOneWidget);
    expect(find.byIcon(LucideIcons.chevronRight), findsOneWidget);
    expect(find.byIcon(LucideIcons.chevronDown), findsNothing);
  });

  testWidgets('without a label it shows the value alone (threshold row)',
      (tester) async {
    await pump(
      tester,
      BudgetNavField(
        value: 'Avisarme al 80% del presupuesto',
        icon: LucideIcons.bell,
        onTap: () {},
      ),
    );

    expect(find.text('Avisarme al 80% del presupuesto'), findsOneWidget);
  });

  testWidgets('a long value stays on one line and truncates', (tester) async {
    await pump(
      tester,
      BudgetNavField(
        label: 'Cuentas',
        value: 'Bancolombia Ahorros, Nequi, Davivienda y Tarjeta Visa Infinite',
        icon: LucideIcons.wallet,
        onTap: () {},
      ),
    );

    final text = tester.widget<Text>(find.byType(Text));
    expect(text.maxLines, 1);
    expect(text.overflow, TextOverflow.ellipsis);
    expect(tester.takeException(), isNull);
  });

  testWidgets('swaps the chevron for a clear action when it can be cleared',
      (tester) async {
    var cleared = false;
    await pump(
      tester,
      BudgetNavField(
        label: 'Repetir hasta',
        value: '30 de junio 2026',
        icon: LucideIcons.repeat,
        onTap: () {},
        onCleared: () => cleared = true,
      ),
    );

    expect(find.byIcon(LucideIcons.chevronRight), findsNothing);
    await tester.tap(find.byIcon(LucideIcons.x));
    expect(cleared, isTrue);
  });
}
