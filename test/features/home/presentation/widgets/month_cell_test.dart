import 'dart:ui' show Tristate;

import 'package:billetudo/core/theme/app_colors.dart';
import 'package:billetudo/features/home/presentation/widgets/month_cell.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'pump_widget.dart';

/// Non-golden coverage for [MonthCell]'s three states (`MonthPickerSheet`'s
/// grid, `DB3bz`): selected (filled `$primary`), normal, and future/disabled
/// (dimmed, not tappable). Pixel-level look is covered by
/// `home_page_golden_test.dart`'s month picker case, if any; this asserts the
/// state machine itself.
void main() {
  testWidgets('normal: no está relleno, tocarlo dispara onTap',
      (tester) async {
    var tapped = 0;
    await tester.pumpHomeWidget(
      MonthCell(
        label: 'Ene',
        isSelected: false,
        isDisabled: false,
        onTap: () => tapped++,
      ),
    );

    final material = tester.widget<Material>(
      find.descendant(
        of: find.byType(MonthCell),
        matching: find.byType(Material),
      ),
    );
    expect(material.color, Colors.transparent);

    await tester.tap(find.byType(MonthCell));
    await tester.pump();
    expect(tapped, 1);

    final semantics = tester.getSemantics(find.byType(MonthCell));
    expect(semantics.flagsCollection.isSelected, isNot(Tristate.isTrue));
    expect(semantics.flagsCollection.isEnabled, isNot(Tristate.isFalse));
  });

  testWidgets(r'seleccionado: relleno $primary y semántica selected',
      (tester) async {
    await tester.pumpHomeWidget(
      MonthCell(
        label: 'Jul',
        isSelected: true,
        isDisabled: false,
        onTap: () {},
      ),
    );

    final context = tester.element(find.byType(MonthCell));
    final colors = context.colors;
    final material = tester.widget<Material>(
      find.descendant(
        of: find.byType(MonthCell),
        matching: find.byType(Material),
      ),
    );
    expect(material.color, colors.primary);

    final semantics = tester.getSemantics(find.byType(MonthCell));
    expect(semantics.flagsCollection.isSelected, Tristate.isTrue);
  });

  testWidgets(
      'futuro/deshabilitado: no dispara onTap y semántica lo marca '
      'deshabilitado', (tester) async {
    var tapped = 0;
    await tester.pumpHomeWidget(
      MonthCell(
        label: 'Dic',
        isSelected: false,
        isDisabled: true,
        onTap: () => tapped++,
      ),
    );

    await tester.tap(find.byType(MonthCell), warnIfMissed: false);
    await tester.pump();

    expect(tapped, 0);
    final semantics = tester.getSemantics(find.byType(MonthCell));
    expect(semantics.flagsCollection.isEnabled, Tristate.isFalse);
  });
}
