import 'package:billetudo/features/auth/presentation/pages/account_deleted_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../widgets/pump_widget.dart';

void main() {
  testWidgets(
      'HU-07 paso 3: cierre neutral que solo habla de la nube, nunca de '
      'los datos locales', (tester) async {
    await tester.pumpAuthWidget(
      AccountDeletedPage(onGoHome: () {}),
      wrapInScaffold: false,
    );

    expect(find.text('Listo, tu cuenta fue eliminada'), findsOneWidget);
    expect(
      find.text(
        'Ya no tenemos ningún dato tuyo en la nube. Puedes seguir usando '
        'billetudo cuando quieras, con o sin cuenta.',
      ),
      findsOneWidget,
    );
    // Deliberately says nothing about local data one way or the other.
    expect(find.textContaining('dispositivo'), findsNothing);
    expect(find.byIcon(Icons.check), findsOneWidget);
  });

  testWidgets('el CTA "Ir al inicio" dispara onGoHome', (tester) async {
    var wentHome = false;
    await tester.pumpAuthWidget(
      AccountDeletedPage(onGoHome: () => wentHome = true),
      wrapInScaffold: false,
    );

    await tester.tap(find.text('Ir al inicio'));
    await tester.pump();

    expect(wentHome, isTrue);
  });
}
