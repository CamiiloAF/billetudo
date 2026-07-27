import 'package:billetudo/core/theme/app_theme.dart';
import 'package:billetudo/features/transactions/presentation/widgets/transaction_form_field_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

void main() {
  Widget appWith(Widget child) => MaterialApp(
        theme: AppTheme.light(),
        home: Scaffold(body: child),
      );

  testWidgets(
      'siempre muestra un chevron-down al final, aunque no haya inlineIcon',
      (tester) async {
    await tester.pumpWidget(
      appWith(
        TransactionFormFieldButton(
          label: 'Fecha',
          value: 'Hoy',
          onTap: () {},
        ),
      ),
    );

    expect(find.byIcon(LucideIcons.chevronDown), findsOneWidget);
  });

  testWidgets('con inlineIcon: lo pinta antes del valor, además del chevron',
      (tester) async {
    await tester.pumpWidget(
      appWith(
        TransactionFormFieldButton(
          label: 'Cuenta',
          value: 'Nequi',
          inlineIcon: LucideIcons.wallet,
          onTap: () {},
        ),
      ),
    );

    expect(find.byIcon(LucideIcons.wallet), findsOneWidget);
    expect(find.byIcon(LucideIcons.chevronDown), findsOneWidget);
  });

  testWidgets('con onCleared y hasValue: pinta una x en vez del chevron',
      (tester) async {
    var cleared = false;
    await tester.pumpWidget(
      appWith(
        TransactionFormFieldButton(
          label: 'Termina',
          value: '12 dic 2026',
          onCleared: () => cleared = true,
          onTap: () {},
        ),
      ),
    );

    expect(find.byIcon(LucideIcons.x), findsOneWidget);
    expect(find.byIcon(LucideIcons.chevronDown), findsNothing);

    await tester.tap(find.byIcon(LucideIcons.x));
    await tester.pump();
    expect(cleared, isTrue);
  });

  testWidgets('con onCleared pero sin valor: sigue mostrando el chevron',
      (tester) async {
    await tester.pumpWidget(
      appWith(
        TransactionFormFieldButton(
          label: 'Termina',
          value: 'Sin fecha de fin',
          hasValue: false,
          onCleared: () {},
          onTap: () {},
        ),
      ),
    );

    expect(find.byIcon(LucideIcons.chevronDown), findsOneWidget);
    expect(find.byIcon(LucideIcons.x), findsNothing);
  });

  testWidgets('tocar la caja dispara onTap una vez', (tester) async {
    var tapCount = 0;
    await tester.pumpWidget(
      appWith(
        TransactionFormFieldButton(
          label: 'Cuenta',
          value: 'Nequi',
          onTap: () => tapCount++,
        ),
      ),
    );

    await tester.tap(find.text('Nequi'));
    await tester.pump();

    expect(tapCount, 1);
  });
}
