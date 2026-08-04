import 'package:billetudo/features/onboarding/presentation/pages/backup_intro_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../widgets/pump_widget.dart';

void main() {
  Future<void> pumpBackup(
    WidgetTester tester, {
    VoidCallback? onActivarRespaldo,
    VoidCallback? onDespues,
  }) =>
      tester.pumpOnboardingWidget(
        BackupIntroPage(
          onActivarRespaldo: onActivarRespaldo ?? () {},
          onDespues: onDespues ?? () {},
        ),
      );

  testWidgets('HU-07: explica el respaldo y ofrece las dos acciones',
      (tester) async {
    await pumpBackup(tester);

    expect(
      find.text('Respalda tus datos, cuando quieras'),
      findsOneWidget,
    );
    expect(find.text('Activar respaldo'), findsOneWidget);
    expect(find.text('Después'), findsOneWidget);
  });

  testWidgets('"Activar respaldo" invoca onActivarRespaldo', (tester) async {
    var tapped = false;
    await pumpBackup(tester, onActivarRespaldo: () => tapped = true);

    await tester.tap(find.text('Activar respaldo'));
    await tester.pump();

    expect(tapped, isTrue);
  });

  testWidgets('"Después" invoca onDespues', (tester) async {
    var tapped = false;
    await pumpBackup(tester, onDespues: () => tapped = true);

    await tester.tap(find.text('Después'));
    await tester.pump();

    expect(tapped, isTrue);
  });
}
