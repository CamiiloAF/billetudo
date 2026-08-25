import 'package:billetudo/core/l10n/gen/app_localizations.dart';
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
          locale: const Locale('es'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
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

  testWidgets(
      'a presupuestable income row (isIncome=true) shows a "+" instead '
      'of a "-"', (tester) async {
    final incomeItem = BudgetActivityItem(
      id: 'tx-2',
      title: 'Repago de préstamo',
      accountName: 'Bancolombia',
      amountMinor: 1000000,
      currency: 'COP',
      date: DateTime(2025, 7, 28),
      categoryIcon: 'hand-coins',
      categoryColor: 'sky',
      isIncome: true,
    );
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        locale: const Locale('es'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: BudgetActivityRow(item: incomeItem, onTap: (_) {}),
        ),
      ),
    );

    expect(find.textContaining(r'+$10.000'), findsOneWidget);
    expect(find.textContaining(r'-$10.000'), findsNothing);
  });

  group('a netted internal transfer row (isNettedTransfer=true)', () {
    final nettedItem = BudgetActivityItem(
      id: 'tx-transfer',
      title: 'ignored',
      accountName: 'Ahorros',
      secondaryAccountName: 'Corriente',
      amountMinor: 0,
      currency: 'COP',
      date: DateTime(2025, 7, 28),
      isNettedTransfer: true,
    );

    Future<void> pumpNetted(WidgetTester tester) => tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.light(),
            locale: const Locale('es'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: Scaffold(
              body: BudgetActivityRow(item: nettedItem, onTap: (_) {}),
            ),
          ),
        );

    testWidgets('shows the fixed title, never the item.title', (
      tester,
    ) async {
      await pumpNetted(tester);

      expect(find.text('Transferencia interna'), findsOneWidget);
      expect(find.text('ignored'), findsNothing);
    });

    testWidgets('the subtitle reads "origen ↔ destino · fecha"', (
      tester,
    ) async {
      await pumpNetted(tester);

      expect(find.textContaining('Ahorros ↔ Corriente'), findsOneWidget);
      expect(find.textContaining('jul'), findsOneWidget);
    });

    testWidgets('the amount is unsigned \$0, never +/-', (tester) async {
      await pumpNetted(tester);

      expect(find.text(r'$0'), findsOneWidget);
    });
  });
}
