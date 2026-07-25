import 'package:billetudo/core/theme/app_theme.dart';
import 'package:billetudo/core/widgets/app_switch.dart';
import 'package:billetudo/core/widgets/toggle_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// `ToggleField` (`gZyEC`, `reusable:true`) — first used by the
/// transferencia presupuestable toggle
/// (`design-system/billetudo/pages/transacciones.md`, Adición 2026-07-24).
void main() {
  Future<void> pump(
    WidgetTester tester, {
    required bool value,
    required ValueChanged<bool> onChanged,
  }) =>
      tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light(),
          home: Scaffold(
            body: ToggleField(
              icon: LucideIcons.wallet,
              label: 'label de prueba',
              value: value,
              hint: value ? 'hint ON' : 'hint OFF',
              onChanged: onChanged,
            ),
          ),
        ),
      );

  testWidgets('renderiza el label y el hint recibidos', (tester) async {
    await pump(tester, value: false, onChanged: (_) {});

    expect(find.text('label de prueba'), findsOneWidget);
    expect(find.text('hint OFF'), findsOneWidget);
  });

  testWidgets('tocar cualquier parte de la fila reporta el valor opuesto',
      (tester) async {
    bool? reported;
    await pump(
      tester,
      value: false,
      onChanged: (v) => reported = v,
    );

    // Tap on the label text, not the AppSwitch itself: the accessibility fix
    // documented on the widget wraps the WHOLE row in the InkWell, not just
    // the 48x28 switch.
    await tester.tap(find.text('label de prueba'));
    await tester.pump();

    expect(reported, isTrue);
  });

  testWidgets('tocar de nuevo con value=true reporta false', (tester) async {
    bool? reported;
    await pump(
      tester,
      value: true,
      onChanged: (v) => reported = v,
    );

    await tester.tap(find.byType(ToggleField));
    await tester.pump();

    expect(reported, isFalse);
  });

  testWidgets('expone el estado toggled a la semántica de accesibilidad',
      (tester) async {
    await pump(tester, value: true, onChanged: (_) {});

    final toggled =
        tester.getSemantics(find.byType(ToggleField)).flagsCollection.isToggled;
    expect(toggled.name, 'isTrue');
  });

  testWidgets('renderiza un solo AppSwitch reflejando value', (tester) async {
    await pump(tester, value: true, onChanged: (_) {});

    final appSwitch = tester.widget<AppSwitch>(find.byType(AppSwitch));
    expect(appSwitch.value, isTrue);
  });
}
