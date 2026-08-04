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

  Future<void> pumpAndOpen(
    WidgetTester tester, {
    bool showCloseAction = true,
    bool settled = false,
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
                result = await DebtActionsSheet.show(
                  context,
                  debtName: 'Crédito vehicular',
                  showCloseAction: showCloseAction,
                  settled: settled,
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

  testWidgets(
      '"Cerrar deuda" hides the chevron — it never navigates anywhere, it '
      'only closes the debt', (tester) async {
    await pumpAndOpen(tester);

    final closeRow = tester.widget<SheetMenuRow>(
      find.ancestor(
        of: find.text('Cerrar deuda'),
        matching: find.byType(SheetMenuRow),
      ),
    );

    expect(closeRow.showChevron, isFalse);
  });

  group('fix 5: closed/settled debt', () {
    testWidgets(
        'showCloseAction=false (deuda ya cerrada) no ofrece ninguna fila de '
        'cerrar/completar', (tester) async {
      await pumpAndOpen(tester, showCloseAction: false);

      expect(find.text('Cerrar deuda'), findsNothing);
      expect(find.text('Completar deuda'), findsNothing);
      expect(find.text('Editar deuda'), findsOneWidget);
      expect(find.text('Eliminar deuda'), findsOneWidget);
      expect(find.byType(SheetMenuRow), findsNWidgets(2));
    });

    testWidgets(
        'settled=true (saldo en 0, aún no cerrada) muestra "Completar '
        'deuda" en vez de "Cerrar deuda"', (tester) async {
      await pumpAndOpen(tester, settled: true);

      expect(find.text('Completar deuda'), findsOneWidget);
      expect(find.text('Cerrar deuda'), findsNothing);
    });

    testWidgets('tocar "Completar deuda" también pops con .close',
        (tester) async {
      await pumpAndOpen(tester, settled: true);

      await tester.tap(find.text('Completar deuda'));
      await tester.pumpAndSettle();

      expect(result, DebtActionsSheetAction.close);
    });
  });
}
