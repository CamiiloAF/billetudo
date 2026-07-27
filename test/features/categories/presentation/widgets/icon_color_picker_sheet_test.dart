import 'package:billetudo/features/categories/presentation/widgets/icon_color_picker_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'pump_widget.dart';

/// Regression for the "hide, don't dim" fix (`categorias.md`, "Selector de
/// icono y color" > variante bloqueada): a locked subcategory's color grid
/// used to render at `opacity:0.55`; it must now be entirely absent from the
/// tree, with no dangling gap where it used to sit.
void main() {
  testWidgets('color grid: visible when unlocked, absent when locked',
      (tester) async {
    await tester.pumpAppWidget(
      const IconColorPickerSheet(),
    );
    expect(find.byType(CategoryColorSwatch), findsWidgets);
  });

  testWidgets('locked: the 7-swatch color grid is entirely gone, not dimmed',
      (tester) async {
    await tester.pumpAppWidget(
      const IconColorPickerSheet(colorLocked: true),
    );

    expect(find.byType(CategoryColorSwatch), findsNothing);
    expect(find.byType(Opacity), findsNothing);
  });
}
