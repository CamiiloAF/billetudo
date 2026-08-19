import 'package:billetudo/core/l10n/gen/app_localizations.dart';
import 'package:billetudo/core/theme/app_theme.dart';
import 'package:billetudo/core/widgets/brand_wordmark.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Future<void> pumpWordmark(WidgetTester tester) => tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light(),
          locale: const Locale('es'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const Scaffold(body: Center(child: BrandWordmark())),
        ),
      );

  testWidgets('renders "Billetudo" flat, as a single capitalized piece',
      (tester) async {
    await pumpWordmark(tester);

    expect(find.text('Billetudo'), findsOneWidget);
    // The retired lowercase direction split the name across three texts and
    // dotted the "i" with a coin — none of that survives.
    expect(find.text('billetudo'), findsNothing);
    expect(find.text('ı'), findsNothing);
    expect(find.byType(Text), findsOneWidget);
  });

  testWidgets('scales tracking with the font size (-0.045em)', (tester) async {
    await pumpWordmark(tester);

    final style = tester.widget<Text>(find.text('Billetudo')).style!;
    expect(style.fontWeight, FontWeight.w800);
    expect(style.letterSpacing, closeTo(32 * -0.045, 0.001));
  });
}
