import 'package:billetudo/core/theme/app_colors.dart';
import 'package:billetudo/core/theme/app_theme.dart';
import 'package:billetudo/features/transactions/presentation/widgets/filter_chip_pill.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

void main() {
  Widget appWith(Widget child) => MaterialApp(
        theme: AppTheme.light(),
        home: Scaffold(body: child),
      );

  testWidgets('inactivo: fondo surface, sin ícono', (tester) async {
    var tapped = false;
    await tester.pumpWidget(
      appWith(
        FilterChipPill(
          label: 'Categorías',
          active: false,
          onTap: () => tapped = true,
        ),
      ),
    );

    final material = tester.widget<Material>(
      find
          .descendant(
            of: find.byType(FilterChipPill),
            matching: find.byType(Material),
          )
          .first,
    );
    expect(material.color, AppColors.light.surface);
    expect(find.byType(Icon), findsNothing);

    await tester.tap(find.byType(FilterChipPill));
    expect(tapped, isTrue);
  });

  testWidgets(
    'activo: adopta el fondo/borde primary-soft y muestra los íconos pasados',
    (tester) async {
      await tester.pumpWidget(
        appWith(
          FilterChipPill(
            label: 'Bancolombia',
            active: true,
            leadingIcon: LucideIcons.landmark,
            trailingIcon: LucideIcons.chevronDown,
            onTap: () {},
          ),
        ),
      );

      final material = tester.widget<Material>(
        find
            .descendant(
              of: find.byType(FilterChipPill),
              matching: find.byType(Material),
            )
            .first,
      );
      expect(material.color, AppColors.light.primarySoft);
      expect(find.byIcon(LucideIcons.landmark), findsOneWidget);
      expect(find.byIcon(LucideIcons.chevronDown), findsOneWidget);
    },
  );
}
