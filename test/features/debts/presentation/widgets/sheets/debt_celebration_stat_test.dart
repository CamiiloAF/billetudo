import 'package:billetudo/core/theme/app_theme.dart';
import 'package:billetudo/features/debts/presentation/widgets/sheets/debt_celebration_stat.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// One of the felicitación sheet's two stat tiles: just renders its value and
/// label, no logic of its own.
void main() {
  Future<void> pump(WidgetTester tester) => tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light(),
          home: const Scaffold(
            body: DebtCelebrationStat(
                value: r'$4.200.000', label: 'Total pagado'),
          ),
        ),
      );

  testWidgets('renders the value and the label', (tester) async {
    await pump(tester);

    expect(find.text(r'$4.200.000'), findsOneWidget);
    expect(find.text('Total pagado'), findsOneWidget);
  });
}
