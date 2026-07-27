import 'package:billetudo/core/l10n/gen/app_localizations.dart';
import 'package:billetudo/core/theme/app_theme.dart';
import 'package:billetudo/features/scheduled_payments/presentation/widgets/scheduled_payment_editable_amount_field.dart';
import 'package:billetudo/features/transactions/presentation/widgets/numeric_keypad.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Widget appWith(Widget child) => MaterialApp(
        theme: AppTheme.light(),
        locale: const Locale('es'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(body: SingleChildScrollView(child: child)),
      );

  testWidgets('colapsado por defecto: el teclado calculadora no se muestra',
      (tester) async {
    await tester.pumpWidget(
      appWith(
        ScheduledPaymentEditableAmountField(
          amountMinor: 10000,
          currency: 'COP',
          onChanged: (_) {},
        ),
      ),
    );

    expect(find.byType(NumericKeypad), findsNothing);
  });

  testWidgets(
      'tocar la fila expande el teclado calculadora embebido (nunca un AlertDialog)',
      (tester) async {
    await tester.pumpWidget(
      appWith(
        ScheduledPaymentEditableAmountField(
          amountMinor: 10000,
          currency: 'COP',
          onChanged: (_) {},
        ),
      ),
    );

    await tester.tap(find.byType(InkWell).first);
    await tester.pumpAndSettle();

    expect(find.byType(NumericKeypad), findsOneWidget);
    expect(find.byType(AlertDialog), findsNothing);
  });

  testWidgets(
      'teclear un dígito recalcula el monto en centavos (entero) y lo reporta',
      (tester) async {
    int? reported;
    await tester.pumpWidget(
      appWith(
        ScheduledPaymentEditableAmountField(
          amountMinor: 0,
          currency: 'COP',
          onChanged: (value) => reported = value,
        ),
      ),
    );

    await tester.tap(find.byType(InkWell).first);
    await tester.pumpAndSettle();

    await tester.tap(
      find.descendant(of: find.byType(NumericKeypad), matching: find.text('5')),
    );
    await tester.pump();

    expect(reported, 500); // $5.00, entero en centavos.
    expect(reported, isA<int>());
  });
}
