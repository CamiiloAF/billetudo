import 'package:billetudo/core/theme/app_colors.dart';
import 'package:billetudo/core/theme/app_theme.dart';
import 'package:billetudo/features/transactions/presentation/widgets/transaction_form_tag_chip.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

void main() {
  Widget appWith(Widget child) => MaterialApp(
        theme: AppTheme.light(),
        home: Scaffold(body: child),
      );

  testWidgets(
      'asignado (no neutral): fondo primarySoft, texto/ícono primaryOnSoftStrong',
      (tester) async {
    await tester.pumpWidget(
      appWith(TransactionFormTagChip(label: 'Comida', onTap: () {})),
    );

    final material = tester.widget<Material>(
      find.descendant(
        of: find.byType(TransactionFormTagChip),
        matching: find.byType(Material),
      ),
    );
    expect(material.color, AppColors.light.primarySoft);

    final label = tester.widget<Text>(find.text('Comida'));
    expect(label.style?.color, AppColors.light.primaryOnSoftStrong);
    expect(find.byIcon(LucideIcons.x), findsOneWidget);
  });

  testWidgets(
      'neutral (Añadir): fondo surface, borde border 1px, texto/ícono '
      'primaryOnSoftStrong — no muted/textSecondary', (tester) async {
    await tester.pumpWidget(
      appWith(
        TransactionFormTagChip(
          label: 'Añadir',
          icon: LucideIcons.plus,
          removable: false,
          neutral: true,
          onTap: () {},
        ),
      ),
    );

    final material = tester.widget<Material>(
      find.descendant(
        of: find.byType(TransactionFormTagChip),
        matching: find.byType(Material),
      ),
    );
    expect(material.color, AppColors.light.surface);
    expect(material.color, isNot(AppColors.light.muted));

    final container = tester
        .widgetList<Container>(
          find.descendant(
            of: find.byType(TransactionFormTagChip),
            matching: find.byType(Container),
          ),
        )
        .first;
    final decoration = container.decoration! as BoxDecoration;
    expect((decoration.border! as Border).top.color, AppColors.light.border);

    final label = tester.widget<Text>(find.text('Añadir'));
    expect(label.style?.color, AppColors.light.primaryOnSoftStrong);
    expect(label.style?.color, isNot(AppColors.light.textSecondary));

    final icon = tester.widget<Icon>(find.byIcon(LucideIcons.plus));
    expect(icon.color, AppColors.light.primaryOnSoftStrong);
  });

  testWidgets('el tap target respeta el mínimo de 44pt', (tester) async {
    await tester.pumpWidget(
      appWith(TransactionFormTagChip(label: 'Comida', onTap: () {})),
    );

    final size = tester.getSize(find.byType(TransactionFormTagChip));
    expect(size.height, greaterThanOrEqualTo(44));
  });

  testWidgets('tocar el chip dispara onTap una vez', (tester) async {
    var tapCount = 0;
    await tester.pumpWidget(
      appWith(
        TransactionFormTagChip(label: 'Comida', onTap: () => tapCount++),
      ),
    );

    await tester.tap(find.byType(TransactionFormTagChip));
    await tester.pump();

    expect(tapCount, 1);
  });
}
