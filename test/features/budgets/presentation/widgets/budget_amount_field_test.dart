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
    ValueChanged<int?>? onChanged,
  }) =>
      tester.pumpAppWidget(
        SizedBox(
          width: 350,
          child: BudgetAmountField(
            amountMinor: amountMinor,
            currency: currency,
            onChanged: onChanged ?? (_) {},
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

  testWidgets('what the user types is grouped as money right away',
      (tester) async {
    int? reported;
    await pump(tester, onChanged: (value) => reported = value);

    await tester.enterText(find.byType(TextFormField), '4500000');
    await tester.pump();

    expect(find.text('4.500.000'), findsOneWidget);
    expect(reported, 450000000);
  });

  testWidgets('clearing the field reports no amount, not zero', (tester) async {
    var reported = 1;
    await pump(tester, amountMinor: 450000000, onChanged: (value) {
      reported = value ?? -1;
    });

    await tester.enterText(find.byType(TextFormField), '');
    await tester.pump();

    expect(reported, -1);
  });

  testWidgets('a currency with cents keeps them', (tester) async {
    await pump(tester, amountMinor: 123456, currency: 'USD');

    expect(find.text(r'$'), findsOneWidget);
    expect(find.text('1.234,56'), findsOneWidget);
  });

  testWidgets('switching to a currency with cents re-renders what was typed',
      (tester) async {
    // The field owns a controller now: an `initialValue` was read once and the
    // typed figure kept the old currency's precision forever.
    await pump(tester, amountMinor: 450000000);
    await tester.enterText(find.byType(TextFormField), '4.500.000');
    await tester.pump();

    await pump(tester, amountMinor: 450000000, currency: 'USD');
    await tester.pump();

    expect(find.text('4.500.000,00'), findsOneWidget);
  });

  testWidgets('switching to a currency without cents drops them from the text',
      (tester) async {
    await pump(tester, amountMinor: 123456, currency: 'USD');
    expect(find.text('1.234,56'), findsOneWidget);

    // What the cubit does on the same change: round first, then re-render.
    await pump(tester, amountMinor: 123500);
    await tester.pump();

    expect(find.text('1.235'), findsOneWidget);
    expect(find.text('1.234,56'), findsNothing);
  });

  testWidgets('an empty field survives a currency change still empty',
      (tester) async {
    await pump(tester, currency: 'USD');
    await pump(tester);
    await tester.pump();

    expect(find.text('0'), findsOneWidget); // The hint, not a typed zero.
    expect(tester.widget<TextField>(find.byType(TextField)).controller?.text,
        isEmpty);
  });

  testWidgets('the caret stays put while typing without a currency change',
      (tester) async {
    await pump(tester, amountMinor: 450000000);
    final field = find.byType(TextFormField);

    await tester.enterText(field, '4.500.000');
    await tester.pump();
    // Put the caret in the middle, as tapping mid-figure would.
    final controller =
        tester.widget<TextField>(find.byType(TextField)).controller!;
    controller.selection = const TextSelection.collapsed(offset: 3);

    // A rebuild with the same currency must not touch the text or the caret.
    await pump(tester, amountMinor: 450000000);
    await tester.pump();

    expect(controller.text, '4.500.000');
    expect(controller.selection.baseOffset, 3);
  });

  testWidgets('the caret lands at the end after a currency change',
      (tester) async {
    await pump(tester, amountMinor: 123456, currency: 'USD');
    final controller =
        tester.widget<TextField>(find.byType(TextField)).controller!;
    controller.selection = const TextSelection.collapsed(offset: 8);

    await pump(tester, amountMinor: 123500);
    await tester.pump();

    // The old offset counted characters of a figure that no longer exists.
    expect(controller.text, '1.235');
    expect(controller.selection.baseOffset, controller.text.length);
  });
}
