import 'package:billetudo/features/categories/domain/entities/category.dart';
import 'package:billetudo/features/categories/presentation/pages/categories_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'pump_widget.dart';

void main() {
  testWidgets('muestra los 2 segmentos, Gasto e Ingreso, nunca Transferencia', (
    tester,
  ) async {
    await tester.pumpAppWidget(
      CategoryKindToggle(selected: CategoryKind.expense, onChanged: (_) {}),
    );

    expect(find.text('Gasto'), findsOneWidget);
    expect(find.text('Ingreso'), findsOneWidget);
    expect(find.text('Transferencia'), findsNothing);
  });

  testWidgets('tocar "Ingreso" llama a onChanged con CategoryKind.income', (
    tester,
  ) async {
    CategoryKind? picked;
    await tester.pumpAppWidget(
      CategoryKindToggle(
        selected: CategoryKind.expense,
        onChanged: (kind) => picked = kind,
      ),
    );

    await tester.tap(find.text('Ingreso'));
    await tester.pump();

    expect(picked, CategoryKind.income);
  });

  testWidgets('"Gasto" nunca se pinta en el tono de \$expense (tono de marca)',
      (
    tester,
  ) async {
    await tester.pumpAppWidget(
      CategoryKindToggle(selected: CategoryKind.expense, onChanged: (_) {}),
    );

    final text = tester.widget<Text>(find.text('Gasto'));
    // No debe usar el rojo de \$expense: el color viene de textPrimary.
    expect(text.style?.color, isNot(const Color(0xFFDC2626)));
  });
}
