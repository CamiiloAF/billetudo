import 'package:billetudo/core/l10n/gen/app_localizations.dart';
import 'package:billetudo/core/theme/app_theme.dart';
import 'package:billetudo/features/debts/presentation/widgets/sheets/confirm_delete_debt_entry_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// Fix B: confirms deleting a single solo-deuda movement from
/// `DebtMovementDetailSheet`'s "Eliminar" action — same
/// Cancelar/Eliminar → false/true contract as `DebtCloseConfirmSheet`.
void main() {
  bool? result;

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
                result = await ConfirmDeleteDebtEntrySheet.show(context);
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

  testWidgets('renders the destructive-delete title, message and icon',
      (tester) async {
    await pumpAndOpen(tester);

    expect(find.text('¿Eliminar este movimiento?'), findsOneWidget);
    expect(find.text('Podrás recuperarlo más adelante.'), findsOneWidget);
    expect(find.byIcon(LucideIcons.trash2), findsWidgets);
    expect(find.text('Cancelar'), findsOneWidget);
    expect(find.text('Eliminar'), findsOneWidget);
  });

  testWidgets('tapping "Cancelar" resolves with false', (tester) async {
    await pumpAndOpen(tester);

    await tester.tap(find.text('Cancelar'));
    await tester.pumpAndSettle();

    expect(result, false);
  });

  testWidgets('tapping "Eliminar" resolves with true', (tester) async {
    await pumpAndOpen(tester);

    await tester.tap(find.text('Eliminar'));
    await tester.pumpAndSettle();

    expect(result, true);
  });
}
