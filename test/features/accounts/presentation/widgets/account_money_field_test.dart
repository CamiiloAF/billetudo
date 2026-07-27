import 'package:billetudo/features/accounts/presentation/widgets/account_money_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'pump_widget.dart';

/// The money fields of the account form (opening balance / current debt and
/// credit limit) must re-render when the currency changes **with a figure
/// already typed** — an `initialValue` was read once and kept showing cents
/// under a COP that has none.
///
/// The cubit rounds the amount before the field ever sees it, so these pumps
/// pass the text the state would hold after the change.
void main() {
  Future<void> pump(
    WidgetTester tester, {
    required String text,
    String currency = 'COP',
    bool allowNegative = false,
    ValueChanged<String>? onChanged,
  }) =>
      tester.pumpAppWidget(
        AccountMoneyField(
          label: 'Saldo inicial',
          currency: currency,
          text: text,
          allowNegative: allowNegative,
          onChanged: onChanged ?? (_) {},
        ),
      );

  TextEditingController controllerOf(WidgetTester tester) =>
      tester.widget<TextField>(find.byType(TextField)).controller!;

  testWidgets('it starts on whatever the state already holds', (tester) async {
    await pump(tester, text: '4.500.000');

    expect(find.text('4.500.000'), findsOneWidget);
  });

  testWidgets('switching to a currency with cents re-renders the figure',
      (tester) async {
    await pump(tester, text: '4.500.000');

    await pump(tester, text: '4.500.000,00', currency: 'USD');
    await tester.pump();

    expect(controllerOf(tester).text, '4.500.000,00');
  });

  testWidgets('switching to a currency without cents drops them',
      (tester) async {
    await pump(tester, text: '1.234,56', currency: 'USD');

    await pump(tester, text: '1.235');
    await tester.pump();

    expect(controllerOf(tester).text, '1.235');
    expect(find.text('1.234,56'), findsNothing);
  });

  testWidgets('a negative balance keeps its sign through the change',
      (tester) async {
    await pump(
      tester,
      text: '-1.234,56',
      currency: 'USD',
      allowNegative: true,
    );

    await pump(tester, text: '-1.235', allowNegative: true);
    await tester.pump();

    expect(controllerOf(tester).text, '-1.235');
  });

  testWidgets('an empty field survives a currency change still empty',
      (tester) async {
    await pump(tester, text: '', currency: 'USD');

    await pump(tester, text: '');
    await tester.pump();

    expect(controllerOf(tester).text, isEmpty);
  });

  testWidgets('typing without a currency change never moves the caret',
      (tester) async {
    await pump(tester, text: '4.500.000');
    final controller = controllerOf(tester);
    controller.selection = const TextSelection.collapsed(offset: 3);

    // The parent rebuilds on every keystroke; the text must not be rewritten.
    await pump(tester, text: '4.500.000');
    await tester.pump();

    expect(controller.text, '4.500.000');
    expect(controller.selection.baseOffset, 3);
  });

  testWidgets('the caret lands at the end after a currency change',
      (tester) async {
    await pump(tester, text: '1.234,56', currency: 'USD');
    final controller = controllerOf(tester)
      ..selection = const TextSelection.collapsed(offset: 8);

    await pump(tester, text: '1.235');
    await tester.pump();

    // The old offset counted characters of a figure that no longer exists.
    expect(controller.selection.baseOffset, controller.text.length);
  });

  testWidgets('the COP field refuses a decimal separator after the switch',
      (tester) async {
    var reported = '';
    await pump(tester, text: '', currency: 'USD');
    await pump(tester, text: '', onChanged: (value) => reported = value);

    await tester.enterText(find.byType(TextField), '1234,56');
    await tester.pump();

    expect(reported, '1.234');
  });
}
