import 'package:billetudo/core/l10n/gen/app_localizations.dart';
import 'package:billetudo/core/theme/app_theme.dart';
import 'package:billetudo/features/budgets/presentation/widgets/budget_threshold_option.dart';
import 'package:billetudo/features/budgets/presentation/widgets/sheets/budget_threshold_custom_sheet.dart';
import 'package:billetudo/features/budgets/presentation/widgets/sheets/budget_threshold_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

void main() {
  BudgetThresholdChoice? result;

  Future<void> pump(WidgetTester tester, {int? selected = 80}) {
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
              onPressed: () async => result = await BudgetThresholdSheet.show(
                context,
                selected: selected,
              ),
              child: const Text('open'),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> open(WidgetTester tester) async {
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
  }

  group('BudgetThresholdSheet', () {
    testWidgets('picking an option does not save until "Aplicar"',
        (tester) async {
      await pump(tester);
      await open(tester);

      await tester.tap(find.text('70%'));
      await tester.pumpAndSettle();
      expect(find.byType(BudgetThresholdSheet), findsOneWidget);
      expect(result, isNull);

      final context = tester.element(find.byType(BudgetThresholdSheet));
      await tester.tap(find.text(AppLocalizations.of(context).commonApply));
      await tester.pumpAndSettle();

      expect(result?.pct, 70);
    });

    testWidgets('"No avisarme" applies a real null, not a dismissal',
        (tester) async {
      await pump(tester);
      await open(tester);

      final context = tester.element(find.byType(BudgetThresholdSheet));
      final l10n = AppLocalizations.of(context);
      await tester.tap(find.text(l10n.budgetFormThresholdOff));
      await tester.pumpAndSettle();
      await tester.tap(find.text(l10n.commonApply));
      await tester.pumpAndSettle();

      expect(result, isNotNull);
      expect(result?.pct, isNull);
    });

    testWidgets(
        '"Personalizado" navigates to its own sheet instead of '
        'stepping inline', (tester) async {
      await pump(tester);
      await open(tester);

      final context = tester.element(find.byType(BudgetThresholdSheet));
      final l10n = AppLocalizations.of(context);
      expect(find.byType(BudgetThresholdCustomSheet), findsNothing);

      await tester.tap(find.text(l10n.budgetThresholdCustom));
      await tester.pumpAndSettle();

      expect(find.byType(BudgetThresholdCustomSheet), findsOneWidget);
    });

    testWidgets('the custom value comes back as the sheet\'s selection',
        (tester) async {
      await pump(tester);
      await open(tester);

      final context = tester.element(find.byType(BudgetThresholdSheet));
      final l10n = AppLocalizations.of(context);
      await tester.tap(find.text(l10n.budgetThresholdCustom));
      await tester.pumpAndSettle();
      await tester.tap(
        find.descendant(
          of: find.byType(BudgetThresholdCustomSheet),
          matching: find.text(l10n.commonApply),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('85%'), findsOneWidget);

      await tester.tap(find.text(l10n.commonApply));
      await tester.pumpAndSettle();

      expect(result?.pct, 85);
    });

    testWidgets(
        'the picked "Personalizado" row shows the check next to its chevron',
        (tester) async {
      await pump(tester, selected: 85);
      await open(tester);

      final custom = find.ancestor(
        of: find.text('85%'),
        matching: find.byType(BudgetThresholdOption),
      );
      expect(custom, findsOneWidget);
      expect(
        find.descendant(of: custom, matching: find.byIcon(LucideIcons.check)),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: custom,
          matching: find.byIcon(LucideIcons.chevronRight),
        ),
        findsOneWidget,
      );
      // The selection is not carried by font weight alone.
      expect(
        tester.getSemantics(custom).hasFlag(SemanticsFlag.isSelected),
        isTrue,
      );
    });
  });
}
