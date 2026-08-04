import 'package:billetudo/features/onboarding/presentation/pages/closing_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../widgets/pump_widget.dart';

void main() {
  Future<void> pumpClosing(
    WidgetTester tester, {
    required bool accountSkipped,
    VoidCallback? onPrimary,
    VoidCallback? onSkip,
  }) =>
      tester.pumpOnboardingWidget(
        ClosingPage(
          accountSkipped: accountSkipped,
          onPrimary: onPrimary ?? () {},
          onSkip: onSkip ?? () {},
        ),
      );

  testWidgets(
      'HU-04: con cuenta creada, invita a registrar el primer movimiento',
      (tester) async {
    await pumpClosing(tester, accountSkipped: false);

    expect(find.text('Tu billetera está lista'), findsOneWidget);
    expect(find.text('Registra tu primer movimiento'), findsOneWidget);
    expect(find.text('Lo hago después'), findsOneWidget);
  });

  testWidgets(
      'HU-04: si se omitió la cuenta, el CTA cambia a crear la cuenta',
      (tester) async {
    await pumpClosing(tester, accountSkipped: true);

    expect(
      find.text(
        'Para registrar movimientos necesitas una cuenta. '
        'Crea la primera en un momento.',
      ),
      findsOneWidget,
    );
    expect(find.text('Crea tu primera cuenta'), findsOneWidget);
    expect(find.text('Registra tu primer movimiento'), findsNothing);
  });

  testWidgets('el CTA principal invoca onPrimary', (tester) async {
    var tapped = false;
    await pumpClosing(
      tester,
      accountSkipped: false,
      onPrimary: () => tapped = true,
    );

    await tester.tap(find.text('Registra tu primer movimiento'));
    await tester.pump();

    expect(tapped, isTrue);
  });

  testWidgets('"Lo hago después" invoca onSkip', (tester) async {
    var tapped = false;
    await pumpClosing(
      tester,
      accountSkipped: false,
      onSkip: () => tapped = true,
    );

    await tester.tap(find.text('Lo hago después'));
    await tester.pump();

    expect(tapped, isTrue);
  });
}
