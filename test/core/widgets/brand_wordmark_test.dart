import 'package:billetudo/core/l10n/gen/app_localizations.dart';
import 'package:billetudo/core/theme/app_theme.dart';
import 'package:billetudo/core/widgets/brand_wordmark.dart';
import 'package:billetudo/core/widgets/coin_glyph.dart';
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

  testWidgets(
      'renders "b", the dotless i and "lletudo" with a coin glyph as the '
      'dot (never both a natural dot and the coin)', (tester) async {
    await pumpWordmark(tester);

    expect(find.text('b'), findsOneWidget);
    expect(find.text('ı'), findsOneWidget);
    expect(find.text('i'), findsNothing);
    expect(find.text('lletudo'), findsOneWidget);
    expect(find.byType(CoinGlyph), findsOneWidget);
  });
}
