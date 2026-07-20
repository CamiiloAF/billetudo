import 'package:billetudo/core/theme/app_theme.dart';
import 'package:billetudo/features/budgets/presentation/widgets/budget_icon_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

void main() {
  Future<void> pump(WidgetTester tester, {String? icon}) => tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light(),
          home: Scaffold(
            body: BudgetIconButton(icon: icon, onTap: () {}),
          ),
        ),
      );

  group('BudgetIconButton', () {
    testWidgets('with nothing picked it shows a neutral placeholder, never '
        'the AI glyph', (tester) async {
      await pump(tester);

      expect(find.byIcon(LucideIcons.sparkles), findsNothing);
      expect(find.byIcon(LucideIcons.shapes), findsOneWidget);
    });

    testWidgets('with an icon picked it shows that icon', (tester) async {
      await pump(tester, icon: 'shopping-cart');

      expect(find.byIcon(LucideIcons.shoppingCart), findsOneWidget);
      expect(find.byIcon(LucideIcons.shapes), findsNothing);
    });

    testWidgets('always carries the edit badge', (tester) async {
      await pump(tester);

      expect(find.byIcon(LucideIcons.pencil), findsOneWidget);
    });
  });
}
