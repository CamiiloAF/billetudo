import 'package:billetudo/core/l10n/gen/app_localizations.dart';
import 'package:billetudo/core/theme/app_colors.dart';
import 'package:billetudo/core/theme/app_theme.dart';
import 'package:billetudo/features/transactions/domain/entities/transaction.dart';
import 'package:billetudo/features/transactions/domain/entities/transaction_with_details.dart';
import 'package:billetudo/features/transactions/presentation/widgets/transaction_row.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../transaction_fixtures.dart';

void main() {
  Widget appWith(Widget child) => MaterialApp(
        theme: AppTheme.light(),
        locale: const Locale('es'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(body: child),
      );

  testWidgets(
    r'un gasto pinta el monto en $text-primary, NO en rojo (B3GGa/xAk6Y)',
    (tester) async {
      final entry = TransactionWithDetails(
        transaction: buildTransaction(),
        accountName: 'Bancolombia',
        categoryName: 'Comida',
      );

      await tester.pumpWidget(
        appWith(TransactionRow(entry: entry, onTap: () {})),
      );

      final amount = tester.widget<Text>(find.textContaining('100'));
      // An expense is signed with '-' (fix "signo del monto"), but stays in the
      // neutral text-primary color — never red, never punitive.
      expect(amount.data, startsWith('-'));
      expect(amount.style?.color, AppColors.light.textPrimary);
    },
  );

  testWidgets('un ingreso pinta el monto en income-text', (tester) async {
    final entry = TransactionWithDetails(
      transaction: buildTransaction(type: TransactionType.income),
      accountName: 'Bancolombia',
      categoryName: 'Salario',
    );

    await tester.pumpWidget(
      appWith(TransactionRow(entry: entry, onTap: () {})),
    );

    final amount = tester.widget<Text>(find.textContaining('100'));
    expect(amount.data, startsWith('+'));
    expect(amount.style?.color, AppColors.light.incomeText);
  });

  testWidgets('el ícono va en un icon-wrap circular', (tester) async {
    final entry = TransactionWithDetails(
      transaction: buildTransaction(),
      accountName: 'Bancolombia',
      categoryName: 'Comida',
    );

    await tester.pumpWidget(
      appWith(TransactionRow(entry: entry, onTap: () {})),
    );

    final containers = tester.widgetList<Container>(find.byType(Container));
    final hasCircularIconWrap = containers.any((container) {
      final decoration = container.decoration;
      return decoration is BoxDecoration && decoration.shape == BoxShape.circle;
    });
    expect(hasCircularIconWrap, isTrue);
  });

  testWidgets('el subtítulo combina cuenta y fecha', (tester) async {
    final entry = TransactionWithDetails(
      transaction: buildTransaction(date: DateTime(2026, 7, 18)),
      accountName: 'Bancolombia',
      categoryName: 'Comida',
    );

    await tester.pumpWidget(
      appWith(TransactionRow(entry: entry, onTap: () {})),
    );

    expect(find.textContaining('Bancolombia ·'), findsOneWidget);
  });
}
