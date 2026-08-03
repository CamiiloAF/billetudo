import 'package:billetudo/features/onboarding/presentation/pages/welcome_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../widgets/pump_widget.dart';

void main() {
  Future<void> pumpWelcome(
    WidgetTester tester, {
    VoidCallback? onComenzar,
    VoidCallback? onYaTengoCuenta,
  }) =>
      tester.pumpOnboardingWidget(
        WelcomePage(
          onComenzar: onComenzar ?? () {},
          onYaTengoCuenta: onYaTengoCuenta ?? () {},
        ),
      );

  testWidgets('HU-01: muestra la promesa de Nivel 0 y el CTA principal',
      (tester) async {
    await pumpWelcome(tester);

    expect(find.text('Todo lo esencial. Gratis. Para siempre.'), findsOneWidget);
    expect(find.text('Comenzar'), findsOneWidget);
    expect(find.text('Ya tengo cuenta'), findsOneWidget);
  });

  testWidgets('HU-01: no hay botón de retroceso en el primer paso',
      (tester) async {
    await pumpWelcome(tester);

    expect(find.byTooltip('Atrás'), findsNothing);
  });

  testWidgets('"Comenzar" invoca onComenzar', (tester) async {
    var tapped = false;
    await pumpWelcome(tester, onComenzar: () => tapped = true);

    await tester.tap(find.text('Comenzar'));
    await tester.pump();

    expect(tapped, isTrue);
  });

  testWidgets('HU-06: "Ya tengo cuenta" invoca onYaTengoCuenta', (tester) async {
    var tapped = false;
    await pumpWelcome(tester, onYaTengoCuenta: () => tapped = true);

    await tester.tap(find.text('Ya tengo cuenta'));
    await tester.pump();

    expect(tapped, isTrue);
  });
}
