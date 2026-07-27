import 'package:billetudo/core/l10n/gen/app_localizations.dart';
import 'package:billetudo/core/theme/app_theme.dart';
import 'package:billetudo/features/debts/domain/entities/debt.dart';
import 'package:billetudo/features/debts/presentation/widgets/sheets/debt_close_confirm_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../debts_presentation_fixtures.dart';

/// Manual "Cerrar deuda" confirmation (extension, HU-07): shows the pending
/// balance and resolves `true`/`false` depending on Cancelar/Cerrar deuda.
void main() {
  bool? result;

  Future<void> pumpAndOpen(
    WidgetTester tester, {
    required Debt debt,
    required int outstandingMinor,
  }) async {
    result = null;
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        locale: const Locale('es'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () async {
                result = await DebtCloseConfirmSheet.show(
                  context,
                  debt: debt,
                  outstandingMinor: outstandingMinor,
                );
              },
              child: const Text('open'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
  }

  testWidgets('renders the title and the pending balance for an iOwe debt',
      (tester) async {
    await pumpAndOpen(
      tester,
      debt: buildDebt(
        direction: DebtDirection.iOwe,
        counterparty: 'Banco Bogotá',
      ),
      outstandingMinor: 500000,
    );

    expect(find.text('¿Cerrar esta deuda?'), findsOneWidget);
    expect(find.text('Saldo pendiente al cerrar'), findsOneWidget);
    expect(find.text(r'$5.000'), findsOneWidget);
  });

  testWidgets('tapping Cancelar pops with false', (tester) async {
    await pumpAndOpen(
      tester,
      debt: buildDebt(direction: DebtDirection.iOwe),
      outstandingMinor: 500000,
    );

    await tester.tap(find.text('Cancelar'));
    await tester.pumpAndSettle();

    expect(result, false);
  });

  testWidgets('tapping "Cerrar deuda" pops with true', (tester) async {
    await pumpAndOpen(
      tester,
      debt: buildDebt(direction: DebtDirection.iOwe),
      outstandingMinor: 500000,
    );

    await tester.tap(find.text('Cerrar deuda'));
    await tester.pumpAndSettle();

    expect(result, true);
  });

  testWidgets('an owedToMe debt without counterparty still renders a message',
      (tester) async {
    await pumpAndOpen(
      tester,
      debt: buildDebt(direction: DebtDirection.owedToMe),
      outstandingMinor: 0,
    );

    expect(find.text('¿Cerrar esta deuda?'), findsOneWidget);
  });
}
