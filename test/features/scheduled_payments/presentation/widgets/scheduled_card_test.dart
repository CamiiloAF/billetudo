import 'package:billetudo/core/l10n/gen/app_localizations.dart';
import 'package:billetudo/core/theme/app_colors.dart';
import 'package:billetudo/core/theme/app_theme.dart';
import 'package:billetudo/features/scheduled_payments/domain/entities/scheduled_payment.dart';
import 'package:billetudo/features/scheduled_payments/domain/entities/scheduled_payment_summary.dart';
import 'package:billetudo/features/scheduled_payments/presentation/widgets/scheduled_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../scheduled_payment_fixtures.dart';

void main() {
  Widget appWith(Widget child) => MaterialApp(
        theme: AppTheme.light(),
        locale: const Locale('es'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(body: child),
      );

  testWidgets('renders category/account, amount and next date', (tester) async {
    final entry = ScheduledPaymentSummary(
      scheduledPayment: buildScheduledPayment(amountMinor: 25000),
      accountName: 'Bancolombia',
      categoryName: 'Arriendo',
    );

    await tester.pumpWidget(
      appWith(ScheduledCard(entry: entry, onTap: () {})),
    );

    expect(find.text('Arriendo'), findsOneWidget);
    // Expense: amount is prefixed with '-' and never uses income green.
    expect(find.textContaining('-'), findsWidgets);
    expect(find.byType(ScheduledPendingCountChip), findsNothing);
  });

  testWidgets('a template with accumulated pending occurrences shows the ×N chip',
      (tester) async {
    final entry = ScheduledPaymentSummary(
      scheduledPayment: buildScheduledPayment(),
      accountName: 'Bancolombia',
      categoryName: 'Arriendo',
      pendingOccurrenceCount: 3,
    );

    await tester.pumpWidget(
      appWith(ScheduledCard(entry: entry, onTap: () {})),
    );

    expect(find.byType(ScheduledPendingCountChip), findsOneWidget);
    expect(find.text('×3'), findsOneWidget);
  });

  testWidgets('income amount uses incomeText, not textPrimary', (tester) async {
    final entry = ScheduledPaymentSummary(
      scheduledPayment: buildScheduledPayment(
        type: ScheduledPaymentType.income,
        amountMinor: 50000,
      ),
      accountName: 'Bancolombia',
      categoryName: 'Salario',
    );

    await tester.pumpWidget(
      appWith(ScheduledCard(entry: entry, onTap: () {})),
    );

    final amountFinder = find.textContaining('+');
    expect(amountFinder, findsOneWidget);
    final amountText = tester.widget<Text>(amountFinder);
    expect(amountText.style?.color, AppColors.light.incomeText);
  });

  testWidgets('tapping the card triggers onTap once', (tester) async {
    var tapCount = 0;
    final entry = ScheduledPaymentSummary(
      scheduledPayment: buildScheduledPayment(),
      accountName: 'Bancolombia',
      categoryName: 'Arriendo',
    );

    await tester.pumpWidget(
      appWith(ScheduledCard(entry: entry, onTap: () => tapCount++)),
    );

    await tester.tap(find.byType(ScheduledCard));
    await tester.pump();

    expect(tapCount, 1);
  });
}
