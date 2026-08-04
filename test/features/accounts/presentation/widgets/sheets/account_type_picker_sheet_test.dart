import 'package:billetudo/features/accounts/domain/entities/account.dart';
import 'package:billetudo/features/accounts/presentation/widgets/sheets/account_type_picker_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../pump_widget.dart';

void main() {
  testWidgets('lista todos los tipos de cuenta y devuelve el elegido',
      (tester) async {
    AccountType? picked;

    await tester.pumpAppWidget(
      Builder(
        builder: (context) => ElevatedButton(
          onPressed: () async {
            picked = await AccountTypePickerSheet.show(
              context,
              selected: AccountType.savings,
            );
          },
          child: const Text('open'),
        ),
      ),
    );

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    expect(find.text('Selecciona el tipo de cuenta'), findsOneWidget);
    expect(find.text('Ahorros'), findsOneWidget);
    expect(find.text('Efectivo'), findsOneWidget);
    expect(find.text('Tarjeta de crédito'), findsOneWidget);

    await tester.tap(find.text('Tarjeta de crédito'));
    await tester.pumpAndSettle();

    expect(picked, AccountType.card);
  });
}
