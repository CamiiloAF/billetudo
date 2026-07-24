import 'package:billetudo/core/l10n/gen/app_localizations.dart';
import 'package:billetudo/core/theme/app_theme.dart';
import 'package:billetudo/core/widgets/sheet_menu_row.dart';
import 'package:billetudo/features/debts/presentation/widgets/sheets/debt_actions_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// The detail's overflow ("⋮") menu (extension, HU-07): three `SheetMenuRow`s
/// that each pop the sheet with the action the caller should perform.
void main() {
  DebtActionsSheetAction? result;

  Future<void> pumpAndOpen(WidgetTester tester) async {
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
                result = await DebtActionsSheet.show(
                  context,
                  debtName: 'Crédito vehicular',
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

  testWidgets('renders the debt name and the three rows without crashing',
      (tester) async {
    await pumpAndOpen(tester);

    expect(find.text('Crédito vehicular'), findsOneWidget);
    expect(find.text('Editar deuda'), findsOneWidget);
    expect(find.text('Cerrar deuda'), findsOneWidget);
    expect(find.text('Eliminar deuda'), findsOneWidget);
    expect(find.byType(SheetMenuRow), findsNWidgets(3));
  });

  testWidgets('tapping "Editar deuda" pops with .edit', (tester) async {
    await pumpAndOpen(tester);

    await tester.tap(find.text('Editar deuda'));
    await tester.pumpAndSettle();

    expect(result, DebtActionsSheetAction.edit);
  });

  testWidgets('tapping "Cerrar deuda" pops with .close', (tester) async {
    await pumpAndOpen(tester);

    await tester.tap(find.text('Cerrar deuda'));
    await tester.pumpAndSettle();

    expect(result, DebtActionsSheetAction.close);
  });

  testWidgets('tapping "Eliminar deuda" pops with .delete', (tester) async {
    await pumpAndOpen(tester);

    await tester.tap(find.text('Eliminar deuda'));
    await tester.pumpAndSettle();

    expect(result, DebtActionsSheetAction.delete);
  });
}
