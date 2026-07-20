import 'package:billetudo/core/theme/app_theme.dart';
import 'package:billetudo/features/budgets/domain/entities/budget_activity_item.dart';
import 'package:billetudo/features/budgets/presentation/widgets/budget_activity_row.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

void main() {
  setUpAll(() async {
    await initializeDateFormatting('es_CO');
  });

  final item = BudgetActivityItem(
    id: 'tx-1',
    title: 'Mercado Éxito',
    accountName: 'Bancolombia',
    amountMinor: 4500000,
    currency: 'COP',
    date: DateTime(2025, 7, 28),
    categoryIcon: 'shopping-cart',
    categoryColor: 'sky',
  );

  Future<void> pump(WidgetTester tester, {ValueChanged<String>? onTap}) =>
      tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light(),
          home: Scaffold(
            body: BudgetActivityRow(item: item, onTap: onTap ?? (_) {}),
          ),
        ),
      );

  testWidgets('shows the title and the signed amount', (tester) async {
    await pump(tester);

    expect(find.text('Mercado Éxito'), findsOneWidget);
    expect(find.textContaining(r'-$45.000'), findsOneWidget);
  });

  testWidgets('the subtitle reads "Cuenta · Fecha"', (tester) async {
    await pump(tester);

    expect(find.textContaining('Bancolombia'), findsOneWidget);
    expect(find.textContaining('jul'), findsOneWidget);
  });

  testWidgets('tapping the row calls onTap with the real transaction id',
      (tester) async {
    String? tappedId;
    await pump(tester, onTap: (id) => tappedId = id);

    await tester.tap(find.byType(BudgetActivityRow));
    await tester.pumpAndSettle();

    expect(tappedId, 'tx-1');
  });
}
