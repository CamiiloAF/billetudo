import 'package:billetudo/core/l10n/gen/app_localizations.dart';
import 'package:billetudo/core/theme/app_theme.dart';
import 'package:billetudo/features/budgets/presentation/widgets/sheets/budget_icon_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  String? result;

  Future<void> pump(WidgetTester tester, {String? selected}) {
    result = null;
    return tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        locale: const Locale('es'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () async => result =
                  await BudgetIconSheet.show(context, selected: selected),
              child: const Text('open'),
            ),
          ),
        ),
      ),
    );
  }

  group('BudgetIconSheet', () {
    testWidgets('tapping a tile only moves the selection; "Aplicar" returns it',
        (tester) async {
      await pump(tester);
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      final context = tester.element(find.byType(BudgetIconSheet));
      final l10n = AppLocalizations.of(context);

      await tester.tap(find.bySemanticsLabel('bus'));
      await tester.pumpAndSettle();
      expect(find.byType(BudgetIconSheet), findsOneWidget);
      expect(result, isNull);

      await tester.tap(find.text(l10n.commonApply));
      await tester.pumpAndSettle();

      expect(result, 'bus');
    });

    testWidgets('"Aplicar" stays disabled while nothing is picked',
        (tester) async {
      await pump(tester);
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      final context = tester.element(find.byType(BudgetIconSheet));
      final l10n = AppLocalizations.of(context);
      final button = tester.widget<FilledButton>(
        find.ancestor(
          of: find.text(l10n.commonApply),
          matching: find.byType(FilledButton),
        ),
      );

      expect(button.onPressed, isNull);
    });
  });
}
