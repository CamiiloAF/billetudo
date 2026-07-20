import 'package:billetudo/core/theme/app_theme.dart';
import 'package:billetudo/features/budgets/domain/entities/budget_scheduled_item.dart';
import 'package:billetudo/features/budgets/presentation/widgets/budget_scheduled_row.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

void main() {
  setUpAll(() async {
    await initializeDateFormatting('es_CO');
  });

  final item = BudgetScheduledItem(
    id: 'sp-1@2025-07-28T00:00:00.000',
    scheduledPaymentId: 'sp-1',
    title: 'Netflix',
    accountName: 'Bancolombia',
    amountMinor: 4500000,
    currency: 'COP',
    date: DateTime(2025, 7, 28),
    categoryIcon: 'tv',
    categoryColor: 'sky',
  );

  Future<void> pump(
    WidgetTester tester, {
    ValueChanged<String>? onTap,
  }) =>
      tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light(),
          home: Scaffold(
            body: BudgetScheduledRow(item: item, onTap: onTap ?? (_) {}),
          ),
        ),
      );

  testWidgets('shows the title and the unsigned amount, no minus sign',
      (tester) async {
    await pump(tester);

    expect(find.text('Netflix'), findsOneWidget);
    expect(find.textContaining(r'$45.000'), findsOneWidget);
    expect(find.textContaining('-\$45.000'), findsNothing);
  });

  testWidgets('the subtitle reads "Cuenta · Fecha"', (tester) async {
    await pump(tester);

    expect(find.textContaining('Bancolombia'), findsOneWidget);
    expect(find.textContaining('jul'), findsOneWidget);
  });

  testWidgets(
      'tapping the row calls onTap with scheduledPaymentId, not the '
      "occurrence's synthetic id", (tester) async {
    String? tappedId;
    await pump(tester, onTap: (id) => tappedId = id);

    await tester.tap(find.byType(BudgetScheduledRow));
    await tester.pumpAndSettle();

    expect(tappedId, 'sp-1');
  });
}
