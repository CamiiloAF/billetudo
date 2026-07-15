// App startup smoke test: checks that BilletudoApp builds and shows the
// bootstrap placeholder without errors.

import 'package:billetudo/app.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

void main() {
  setUpAll(() {
    // Stops google_fonts from trying to download fonts during tests.
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  testWidgets('BilletudoApp arranca y muestra el título', (tester) async {
    await tester.pumpWidget(const BilletudoApp());
    await tester.pumpAndSettle();

    expect(find.text('Billetudo'), findsOneWidget);
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
