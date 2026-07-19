import 'package:billetudo/features/budgets/presentation/widgets/budget_amount_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../accounts/presentation/widgets/pump_widget.dart';

/// `a3gGPM/k9OW4h/KP13F`: the figure always reads with the `$` symbol — empty
/// (`$0`) and filled (`$4.500.000`) alike — and never carries decimals for a
/// currency that has none. The symbol is painted outside the editable text, so
/// these assertions look at the two runs separately.
void main() {
  Future<void> pump(
    WidgetTester tester, {
    int? amountMinor,
    String currency = 'COP',
  }) =>
      tester.pumpAppWidget(
        SizedBox(
          width: 350,
          child: BudgetAmountField(
            amountMinor: amountMinor,
            currency: currency,
            onChanged: (_) {},
            onCurrencyTap: () {},
          ),
        ),
      );

  testWidgets('empty it reads the currency zero with its symbol',
      (tester) async {
    await pump(tester);

    expect(find.text(r'$'), findsOneWidget);
    expect(find.text('0'), findsOneWidget);
  });

  testWidgets('filled it keeps the symbol and drops the COP decimals',
      (tester) async {
    await pump(tester, amountMinor: 450000000);

    expect(find.text(r'$'), findsOneWidget);
    expect(find.text('4.500.000'), findsOneWidget);
    expect(find.text('4.500.000,00'), findsNothing);
  });

  testWidgets('a currency with cents keeps them', (tester) async {
    await pump(tester, amountMinor: 123456, currency: 'USD');

    expect(find.text(r'$'), findsOneWidget);
    expect(find.text('1.234,56'), findsOneWidget);
  });
}
