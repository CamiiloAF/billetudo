import 'package:billetudo/core/theme/app_theme.dart';
import 'package:billetudo/core/widgets/coin_glyph.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Future<void> pumpGlyph(WidgetTester tester, {double size = 44}) =>
      tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light(),
          home: Scaffold(body: Center(child: CoinGlyph(size: size))),
        ),
      );

  testWidgets('renders a circular, sized container', (tester) async {
    await pumpGlyph(tester, size: 44);

    expect(tester.getSize(find.byType(CoinGlyph)), const Size(44, 44));

    final container = tester.widget<Container>(find.byType(Container));
    final decoration = container.decoration! as BoxDecoration;
    expect(decoration.shape, BoxShape.circle);
    expect(decoration.gradient, isA<LinearGradient>());
    expect(decoration.border, isNotNull);
  });
}
