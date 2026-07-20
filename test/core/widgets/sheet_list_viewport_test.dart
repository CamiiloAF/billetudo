import 'package:billetudo/core/widgets/sheet_list_viewport.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Widget appWith({required double keyboard, required double screen}) =>
      MediaQuery(
        data: MediaQueryData(
          size: Size(390, screen),
          viewInsets: EdgeInsets.only(bottom: keyboard),
        ),
        child: const Directionality(
          textDirection: TextDirection.ltr,
          // Aligned so the viewport is measured on its own height instead of
          // being forced to fill the tight root constraints.
          child: Align(
            alignment: Alignment.topLeft,
            child: SheetListViewport(
              height: 420,
              child: SizedBox.shrink(),
            ),
          ),
        ),
      );

  testWidgets('sin teclado usa el alto del frame', (tester) async {
    await tester.pumpWidget(appWith(keyboard: 0, screen: 972));

    expect(tester.getSize(find.byType(SheetListViewport)).height, 420);
  });

  testWidgets('con el teclado abierto se recorta al espacio disponible',
      (tester) async {
    await tester.pumpWidget(appWith(keyboard: 340, screen: 972));

    // (972 - 340) * 0.5
    expect(tester.getSize(find.byType(SheetListViewport)).height, 316);
  });

  testWidgets('en una pantalla corta nunca excede la mitad del espacio',
      (tester) async {
    await tester.pumpWidget(appWith(keyboard: 0, screen: 640));

    expect(tester.getSize(find.byType(SheetListViewport)).height, 320);
  });
}
