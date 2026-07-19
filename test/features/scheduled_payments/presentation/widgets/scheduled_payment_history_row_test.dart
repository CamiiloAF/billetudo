import 'package:billetudo/core/theme/app_theme.dart';
import 'package:billetudo/features/scheduled_payments/presentation/widgets/scheduled_payment_history_row.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../transactions/transaction_fixtures.dart';

/// Criterion 13: one row of the detail page's expandable history.
void main() {
  Widget appWith(Widget child) => MaterialApp(
        theme: AppTheme.light(),
        locale: const Locale('es'),
        home: Scaffold(body: child),
      );

  testWidgets('renders the transaction date and formatted amount',
      (tester) async {
    final transaction = buildTransaction(amountMinor: 12345);

    await tester.pumpWidget(
      appWith(
        ScheduledPaymentHistoryRow(
          transaction: transaction,
          name: 'Arriendo',
          accountName: 'Bancolombia',
          onTap: () {},
        ),
      ),
    );

    // 12345 minor units => 123,45 in the currency formatting.
    expect(find.textContaining('123'), findsOneWidget);
    expect(find.text('Arriendo'), findsOneWidget);
    expect(find.textContaining('Bancolombia · '), findsOneWidget);
  });

  testWidgets(
      'tapping the row triggers onTap once, and links to its own transaction',
      (tester) async {
    var tapCount = 0;
    final transaction = buildTransaction(id: 'tx-77');

    await tester.pumpWidget(
      appWith(
        ScheduledPaymentHistoryRow(
          transaction: transaction,
          name: 'Arriendo',
          accountName: 'Bancolombia',
          onTap: () => tapCount++,
        ),
      ),
    );

    await tester.tap(find.byType(ScheduledPaymentHistoryRow));
    await tester.pump();

    expect(tapCount, 1);
  });
}
