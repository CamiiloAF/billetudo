import 'package:billetudo/core/theme/app_colors.dart';
import 'package:billetudo/core/theme/app_theme.dart';
import 'package:billetudo/core/widgets/app_fab.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// `H5mzN`: a 56x56 circle filled with `$primary`, the icon in `$on-primary`
/// and a brand-coloured shadow — not Material's `primaryContainer` squircle.
void main() {
  Widget appWith(Widget child, {Brightness brightness = Brightness.light}) =>
      MaterialApp(
        theme: brightness == Brightness.light
            ? AppTheme.light()
            : AppTheme.dark(),
        home: Scaffold(body: Center(child: child)),
      );

  AppFab buildFab({VoidCallback? onPressed}) => AppFab(
        icon: LucideIcons.plus,
        tooltip: 'Agregar',
        onPressed: onPressed ?? () {},
      );

  testWidgets('mide 56x56 y es un círculo relleno de primary', (tester) async {
    await tester.pumpWidget(appWith(buildFab()));

    expect(tester.getSize(find.byType(AppFab)), const Size(56, 56));

    final material = tester.widget<Material>(
      find.descendant(of: find.byType(AppFab), matching: find.byType(Material)),
    );
    expect(material.color, AppColors.light.primary);
    expect(material.shape, const CircleBorder());
  });

  testWidgets('el icono usa on-primary', (tester) async {
    await tester.pumpWidget(appWith(buildFab()));

    final icon = tester.widget<Icon>(find.byIcon(LucideIcons.plus));
    expect(icon.color, AppColors.light.onPrimary);
  });

  testWidgets('lleva sombra de marca (primary al 40%, blur 16, y+6)',
      (tester) async {
    await tester.pumpWidget(appWith(buildFab()));

    final container = tester.widget<Container>(
      find
          .descendant(of: find.byType(AppFab), matching: find.byType(Container))
          .first,
    );
    final decoration = container.decoration! as BoxDecoration;
    expect(decoration.shape, BoxShape.circle);
    final shadow = decoration.boxShadow!.single;
    expect(shadow.color, AppColors.light.primary.withValues(alpha: 0.4));
    expect(shadow.blurRadius, 16);
    expect(shadow.offset, const Offset(0, 6));
  });

  testWidgets('tema oscuro: resuelve los tokens de AppColors.dark',
      (tester) async {
    await tester.pumpWidget(
      appWith(buildFab(), brightness: Brightness.dark),
    );

    final material = tester.widget<Material>(
      find.descendant(of: find.byType(AppFab), matching: find.byType(Material)),
    );
    expect(material.color, AppColors.dark.primary);
    expect(material.color, isNot(AppColors.light.primary));
  });

  testWidgets('un toque llama onPressed', (tester) async {
    var taps = 0;
    await tester.pumpWidget(appWith(buildFab(onPressed: () => taps++)));

    await tester.tap(find.byType(AppFab));
    await tester.pump();

    expect(taps, 1);
  });
}
