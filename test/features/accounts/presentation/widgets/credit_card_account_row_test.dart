import 'package:billetudo/core/theme/app_colors.dart';
import 'package:billetudo/features/accounts/presentation/widgets/credit_card_account_row.dart';
import 'package:billetudo/features/accounts/presentation/widgets/credit_usage_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../account_fixtures.dart';
import 'pump_widget.dart';

void main() {
  // Cupo 3.000.000, deuda 450.000 -> 15% usado.
  const creditLimitMinor = 300000000;

  CreditCardAccountRow buildRow(int balanceMinor) => CreditCardAccountRow(
        entry: buildAccountWithBalance(
          account: buildCard(
            name: 'Visa Oro',
            creditLimitMinor: creditLimitMinor,
          ),
          balanceMinor: balanceMinor,
        ),
      );

  CreditUsageBar barOf(WidgetTester tester) =>
      tester.widget<CreditUsageBar>(find.byType(CreditUsageBar));

  testWidgets('muestra deuda, cupo disponible y la barra de uso',
      (tester) async {
    await tester.pumpAppWidget(buildRow(-45000000));

    expect(find.text('Visa Oro'), findsOneWidget);
    expect(find.text('Deuda actual'), findsOneWidget);
    expect(find.text('Cupo disponible'), findsOneWidget);
    // Deuda 450.000 y disponible 2.550.000.
    expect(find.textContaining('450.000'), findsWidgets);
    expect(find.textContaining('2.550.000'), findsOneWidget);
    expect(barOf(tester).usedFraction, closeTo(0.15, 0.001));
  });

  testWidgets('sin deuda, la barra queda en cero y nada se pinta de rojo',
      (tester) async {
    await tester.pumpAppWidget(buildRow(0));

    expect(barOf(tester).usedFraction, 0);
    expect(barOf(tester).balance.overLimit, isFalse);
  });

  testWidgets(
      'con sobrecupo la barra llega al 100% en \$expense y el disponible es 0',
      (tester) async {
    // Deuda 3.150.000 sobre un cupo de 3.000.000: excedido en 150.000.
    await tester.pumpAppWidget(buildRow(-315000000));

    final bar = barOf(tester);
    expect(bar.balance.overLimit, isTrue);
    // Nunca "más que llena": el sobrecupo satura en 1.
    expect(bar.usedFraction, 1);

    final indicator = tester.widget<LinearProgressIndicator>(
      find.byType(LinearProgressIndicator),
    );
    expect(indicator.valueColor!.value, AppColors.light.expense);

    // El cupo disponible se muestra en 0, nunca en negativo (HU-02).
    // COP sin decimales: "0 COP", no "0,00".
    expect(find.textContaining('3.150.000'), findsWidgets);
    expect(find.textContaining('0\u{00A0}COP'), findsWidgets);
  });
}
