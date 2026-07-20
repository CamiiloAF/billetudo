import 'package:billetudo/core/theme/app_colors.dart';
import 'package:billetudo/features/home/presentation/widgets/recent_activity_row.dart';
import 'package:billetudo/features/transactions/domain/entities/transaction.dart';
import 'package:billetudo/features/transactions/domain/entities/transaction_with_details.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

import '../../home_fixtures.dart';
import 'pump_widget.dart';

void main() {
  setUpAll(initializeDateFormatting);

  Widget row(TransactionWithDetails entry, {VoidCallback? onTap}) =>
      RecentActivityRow(entry: entry, onTap: onTap ?? () {});

  Color amountColor(WidgetTester tester, String amountText) =>
      tester.widget<Text>(find.text(amountText)).style!.color!;

  testWidgets('gasto: sin signo y color text-primary (nunca rojo, HU-05)',
      (tester) async {
    await tester.pumpHomeWidget(
      row(buildActivity(
        amountMinor: 25000,
        categoryName: 'Mercado',
      )),
    );

    expect(find.text('Mercado'), findsOneWidget);
    expect(find.text(r'-$250'), findsOneWidget);

    final colors = tester.element(find.byType(RecentActivityRow)).colors;
    expect(amountColor(tester, r'-$250'), colors.textPrimary);
  });

  testWidgets('ingreso: signo positivo y color income (verde, HU-05)',
      (tester) async {
    await tester.pumpHomeWidget(
      row(buildActivity(
        amountMinor: 150000,
        type: TransactionType.income,
        categoryName: 'Salario',
      )),
    );

    expect(find.text(r'+$1.500'), findsOneWidget);

    final colors = tester.element(find.byType(RecentActivityRow)).colors;
    expect(amountColor(tester, r'+$1.500'), colors.incomeText);
  });

  testWidgets('transferencia: sin signo, color neutro y título "A → B" (HU-05)',
      (tester) async {
    final entry = TransactionWithDetails(
      transaction: buildActivity(
        amountMinor: 100000,
        type: TransactionType.transfer,
      ).transaction,
      accountName: 'Cuenta A',
      transferAccountName: 'Cuenta B',
    );

    await tester.pumpHomeWidget(row(entry));

    expect(find.text('Cuenta A → Cuenta B'), findsOneWidget);
    expect(find.text(r'$1.000'), findsOneWidget);

    final colors = tester.element(find.byType(RecentActivityRow)).colors;
    expect(amountColor(tester, r'$1.000'), colors.textPrimary);
  });

  testWidgets('sin categoría: cae al nombre de la cuenta como título',
      (tester) async {
    await tester.pumpHomeWidget(
      row(buildActivity()),
    );

    expect(find.text('Bancolombia'), findsWidgets);
  });

  testWidgets('subtítulo en español: mes localizado (es)', (tester) async {
    await tester.pumpHomeWidget(
      row(buildActivity(
        categoryName: 'Mercado',
        date: DateTime(2026, 7, 15),
      )),
    );

    expect(find.textContaining('jul'), findsOneWidget);
  });

  testWidgets('subtítulo en inglés: mes localizado (en, HU dates)',
      (tester) async {
    await tester.pumpHomeWidget(
      row(buildActivity(
        categoryName: 'Groceries',
        date: DateTime(2026, 7, 15),
      )),
      locale: const Locale('en'),
    );

    expect(find.textContaining('Jul'), findsOneWidget);
  });

  testWidgets('tocar la fila dispara onTap', (tester) async {
    var tapped = 0;
    await tester.pumpHomeWidget(
      row(buildActivity(categoryName: 'Mercado'), onTap: () => tapped++),
    );

    await tester.tap(find.byType(RecentActivityRow));
    await tester.pump();

    expect(tapped, 1);
  });
}
