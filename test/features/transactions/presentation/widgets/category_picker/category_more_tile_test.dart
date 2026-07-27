import 'package:billetudo/core/theme/app_colors.dart';
import 'package:billetudo/core/theme/app_theme.dart';
import 'package:billetudo/features/transactions/presentation/widgets/category_picker/category_more_tile.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

void main() {
  Widget appWith(Widget child, {Brightness brightness = Brightness.light}) =>
      MaterialApp(
        theme:
            brightness == Brightness.dark ? AppTheme.dark() : AppTheme.light(),
        home: Scaffold(body: child),
      );

  testWidgets(
      'trata outline: fondo surface, borde 2px del color border, ícono '
      'ellipsis en textSecondary (light)', (tester) async {
    await tester.pumpWidget(
      appWith(CategoryMoreTile(label: 'Ver más', onTap: () {})),
    );

    final decoration = tester
        .widgetList<Container>(
          find.descendant(
            of: find.byType(CategoryMoreTile),
            matching: find.byType(Container),
          ),
        )
        .first
        .decoration! as BoxDecoration;
    expect(decoration.color, AppColors.light.surface);
    expect((decoration.border! as Border).top.color, AppColors.light.border);
    expect((decoration.border! as Border).top.width, 2);

    final icon = tester.widget<Icon>(find.byIcon(LucideIcons.ellipsis));
    expect(icon.color, AppColors.light.textSecondary);

    final label = tester.widget<Text>(find.text('Ver más'));
    expect(label.style?.color, AppColors.light.textSecondary);
  });

  testWidgets('tocar el tile dispara onTap una vez', (tester) async {
    var tapCount = 0;
    await tester.pumpWidget(
      appWith(CategoryMoreTile(label: 'Ver más', onTap: () => tapCount++)),
    );

    await tester.tap(find.byType(CategoryMoreTile));
    await tester.pump();

    expect(tapCount, 1);
  });

  testWidgets(
      'tema oscuro: fondo/borde resuelven AppColors.dark, no los de light',
      (tester) async {
    await tester.pumpWidget(
      appWith(
        CategoryMoreTile(label: 'Ver más', onTap: () {}),
        brightness: Brightness.dark,
      ),
    );

    final decoration = tester
        .widgetList<Container>(
          find.descendant(
            of: find.byType(CategoryMoreTile),
            matching: find.byType(Container),
          ),
        )
        .first
        .decoration! as BoxDecoration;
    expect(decoration.color, AppColors.dark.surface);
    expect(decoration.color, isNot(AppColors.light.surface));
    expect((decoration.border! as Border).top.color, AppColors.dark.border);
    expect(
      (decoration.border! as Border).top.color,
      isNot(AppColors.light.border),
    );
  });
}
