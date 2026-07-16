import 'package:billetudo/core/theme/app_colors.dart';
import 'package:billetudo/features/home/presentation/widgets/home_tab_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'pump_widget.dart';

void main() {
  Widget tabBar({
    int currentIndex = 0,
    ValueChanged<int>? onSelect,
  }) =>
      HomeTabBar(
        currentIndex: currentIndex,
        onSelect: onSelect ?? (_) {},
      );

  testWidgets('muestra los 5 destinos en orden (HU-01)', (tester) async {
    await tester.pumpHomeWidget(tabBar());

    expect(find.byType(HomeTabBarItem), findsNWidgets(5));
    expect(find.text('Inicio'), findsOneWidget);
    expect(find.text('Movimientos'), findsOneWidget);
    expect(find.text('Presupuestos'), findsOneWidget);
    expect(find.text('Metas'), findsOneWidget);
    expect(find.text('Más'), findsOneWidget);
  });

  testWidgets('la pestaña activa se marca como selected en semántica (HU-01)',
      (tester) async {
    await tester.pumpHomeWidget(tabBar(currentIndex: 2));

    final items = tester.widgetList<HomeTabBarItem>(find.byType(HomeTabBarItem));
    expect(
      items.map((i) => i.isActive).toList(),
      [false, false, true, false, false],
    );
  });

  testWidgets('la pestaña activa usa el color de marca; las demás text-secondary',
      (tester) async {
    await tester.pumpHomeWidget(tabBar());

    final ctx = tester.element(find.byType(HomeTabBar));
    final colors = ctx.colors;

    Color iconColor(String label) => tester
        .widget<Icon>(
          find.descendant(
            of: find.ancestor(
              of: find.text(label),
              matching: find.byType(HomeTabBarItem),
            ),
            matching: find.byType(Icon),
          ),
        )
        .color!;

    expect(iconColor('Inicio'), colors.primary);
    expect(iconColor('Metas'), colors.textSecondary);
  });

  testWidgets('tocar una pestaña reporta su índice (HU-01)', (tester) async {
    final selected = <int>[];
    await tester.pumpHomeWidget(tabBar(onSelect: selected.add));

    await tester.tap(find.text('Más'));
    await tester.pump();
    await tester.tap(find.text('Movimientos'));
    await tester.pump();

    expect(selected, [4, 1]);
  });
}
