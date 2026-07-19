import 'package:billetudo/core/l10n/gen/app_localizations.dart';
import 'package:billetudo/core/theme/app_theme.dart';
import 'package:billetudo/core/widgets/budget_usage_notice.dart';
import 'package:billetudo/features/categories/domain/entities/category.dart';
import 'package:billetudo/features/categories/domain/usecases/delete_category.dart';
import 'package:billetudo/features/categories/presentation/widgets/sheets/confirm_delete_root_with_subcategories_sheet.dart';
import 'package:billetudo/features/categories/presentation/widgets/sheets/confirm_delete_simple_sheet.dart';
import 'package:billetudo/features/categories/presentation/widgets/sheets/confirm_delete_with_transactions_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../pump_widget.dart';

void main() {
  group('caso 1: sin dependientes', () {
    testWidgets(
        'icono destructivo alert-triangle (tono expense), sin título, y las '
        '2 acciones', (
      tester,
    ) async {
      await tester.pumpAppWidget(const ConfirmDeleteSimpleSheet());

      // Plain `alert-triangle` pattern (`o9116/qsjbj`): icon + message only,
      // no title.
      expect(
        find.textContaining('Podrás deshacerlo justo después de eliminar'),
        findsOneWidget,
      );
      expect(find.text('Cancelar'), findsOneWidget);
      expect(find.text('Eliminar'), findsOneWidget);
      // Header uses alert-triangle in $expense; the confirm button's icon is
      // trash2 — never the neutral `trash`.
      expect(find.byIcon(LucideIcons.triangleAlert), findsOneWidget);
      expect(find.byIcon(LucideIcons.trash2), findsOneWidget);
      expect(find.byIcon(LucideIcons.trash), findsNothing);
    });

    testWidgets('tocar Eliminar resuelve `true`', (tester) async {
      bool? result;
      await tester.pumpWidget(
        _wrapWithTrigger(
          onPressed: (context) async {
            result = await ConfirmDeleteSimpleSheet.show(context);
          },
        ),
      );

      await tester.tap(find.text('abrir'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Eliminar'));
      await tester.pumpAndSettle();

      expect(result, isTrue);
    });
  });

  group('caso 2: con transacciones asociadas', () {
    testWidgets('muestra el conteo y las 2 opciones tipo radio', (
      tester,
    ) async {
      await tester.pumpAppWidget(
        const ConfirmDeleteWithTransactionsSheet(
          transactionCount: 3,
          kind: CategoryKind.expense,
          excludingId: 'cat-1',
        ),
      );

      expect(
        find.text('Tiene 3 movimientos asociados.'),
        findsOneWidget,
      );
      expect(find.text('Reasignar a otra categoría'), findsOneWidget);
      expect(find.text('Dejar sin categoría'), findsOneWidget);
    });

    testWidgets(
        '"Reasignar" es la opción por defecto: Continuar arranca '
        'deshabilitado hasta elegir destino', (tester) async {
      await tester.pumpAppWidget(
        const ConfirmDeleteWithTransactionsSheet(
          transactionCount: 1,
          kind: CategoryKind.expense,
          excludingId: 'cat-1',
        ),
      );

      // This step never deletes by itself, so the confirm button reads
      // "Continuar" (never "Eliminar"), and stays disabled while "Reasignar"
      // is selected without a resolved target.
      expect(find.text('Eliminar'), findsNothing);
      // `FilledButton.icon` returns a private `_FilledButtonWithIcon`
      // subclass, so `find.byType(FilledButton)` (exact-type match) misses
      // it — match by predicate instead.
      final continueButton = tester.widget<FilledButton>(
        find.ancestor(
          of: find.text('Continuar'),
          matching: find.byWidgetPredicate((widget) => widget is FilledButton),
        ),
      );
      expect(continueButton.onPressed, isNull);
    });

    testWidgets('"Dejar sin categoría" habilita Continuar y resuelve `clear`', (
      tester,
    ) async {
      TransactionResolution? result;
      await tester.pumpWidget(
        _wrapWithTrigger(
          onPressed: (context) async {
            result = await ConfirmDeleteWithTransactionsSheet.show(
              context,
              transactionCount: 1,
              kind: CategoryKind.expense,
              excludingId: 'cat-1',
            );
          },
        ),
      );

      await tester.tap(find.text('abrir'));
      await tester.pumpAndSettle();

      // Switch the radio choice away from the default "Reasignar" to
      // "Dejar sin categoría", which resolves right away (no picker).
      await tester.tap(find.text('Dejar sin categoría'));
      await tester.pumpAndSettle();

      // `FilledButton.icon` returns a private `_FilledButtonWithIcon`
      // subclass, so `find.byType(FilledButton)` (exact-type match) misses
      // it — match by predicate instead.
      final continueButton = tester.widget<FilledButton>(
        find.ancestor(
          of: find.text('Continuar'),
          matching: find.byWidgetPredicate((widget) => widget is FilledButton),
        ),
      );
      expect(continueButton.onPressed, isNotNull);

      await tester.tap(find.text('Continuar'));
      await tester.pumpAndSettle();

      expect(result, const TransactionResolution.clear());
    });
  });

  group('caso 3: raíz con subcategorías activas', () {
    testWidgets('icono info (restricción, no destructivo) y las 2 acciones', (
      tester,
    ) async {
      await tester.pumpAppWidget(
        const ConfirmDeleteRootWithSubcategoriesSheet(
          kind: CategoryKind.expense,
          rootId: 'root-1',
        ),
      );

      expect(find.text('Esta categoría tiene subcategorías'), findsOneWidget);
      expect(find.byIcon(LucideIcons.info), findsOneWidget);
      expect(find.text('Reasignar subcategorías'), findsOneWidget);
      expect(find.text('Eliminar todo en cascada'), findsOneWidget);
      // Un solo botón, a ancho completo: Cancelar.
      expect(find.text('Cancelar'), findsOneWidget);
    });

    testWidgets('"Eliminar todo en cascada" pide una segunda confirmación', (
      tester,
    ) async {
      await tester.pumpAppWidget(
        const ConfirmDeleteRootWithSubcategoriesSheet(
          kind: CategoryKind.expense,
          rootId: 'root-1',
        ),
      );

      await tester.tap(find.text('Eliminar todo en cascada'));
      await tester.pumpAndSettle();

      expect(
        find.text('¿Eliminar la categoría y sus subcategorías?'),
        findsOneWidget,
      );
    });
  });

  group('aviso de impacto en presupuestos (Presupuestos HU-06)', () {
    testWidgets(
        'ConfirmDeleteSimpleSheet: budgetCount > 0 muestra el aviso con el '
        'conteo correcto', (tester) async {
      await tester
          .pumpAppWidget(const ConfirmDeleteSimpleSheet(budgetCount: 2));

      final context = tester.element(find.byType(ConfirmDeleteSimpleSheet));
      final l10n = AppLocalizations.of(context);
      expect(find.text(l10n.deleteImpactBudgets(2)), findsOneWidget);
    });

    testWidgets(
        'ConfirmDeleteSimpleSheet: budgetCount 0 no muestra ningún aviso', (
      tester,
    ) async {
      await tester.pumpAppWidget(const ConfirmDeleteSimpleSheet());

      final noticeUnderSheet = find.descendant(
        of: find.byType(ConfirmDeleteSimpleSheet),
        matching: find.byType(BudgetUsageNotice),
      );
      expect(noticeUnderSheet, findsOneWidget);
      expect(
        find.descendant(of: noticeUnderSheet, matching: find.byType(Text)),
        findsNothing,
      );
    });

    testWidgets(
        'ConfirmDeleteWithTransactionsSheet: budgetCount > 0 muestra el '
        'aviso con el conteo correcto', (tester) async {
      await tester.pumpAppWidget(
        const ConfirmDeleteWithTransactionsSheet(
          transactionCount: 3,
          kind: CategoryKind.expense,
          excludingId: 'cat-1',
          budgetCount: 1,
        ),
      );

      final context =
          tester.element(find.byType(ConfirmDeleteWithTransactionsSheet));
      final l10n = AppLocalizations.of(context);
      expect(find.text(l10n.deleteImpactBudgets(1)), findsOneWidget);
    });

    testWidgets(
        'ConfirmDeleteWithTransactionsSheet: budgetCount 0 no muestra '
        'ningún aviso', (tester) async {
      await tester.pumpAppWidget(
        const ConfirmDeleteWithTransactionsSheet(
          transactionCount: 3,
          kind: CategoryKind.expense,
          excludingId: 'cat-1',
        ),
      );

      final noticeUnderSheet = find.descendant(
        of: find.byType(ConfirmDeleteWithTransactionsSheet),
        matching: find.byType(BudgetUsageNotice),
      );
      expect(noticeUnderSheet, findsOneWidget);
      expect(
        find.descendant(of: noticeUnderSheet, matching: find.byType(Text)),
        findsNothing,
      );
    });

    testWidgets(
        'ConfirmDeleteRootWithSubcategoriesSheet: budgetCount > 0 muestra el '
        'aviso con el conteo correcto', (tester) async {
      await tester.pumpAppWidget(
        const ConfirmDeleteRootWithSubcategoriesSheet(
          kind: CategoryKind.expense,
          rootId: 'root-1',
          budgetCount: 4,
        ),
      );

      final context =
          tester.element(find.byType(ConfirmDeleteRootWithSubcategoriesSheet));
      final l10n = AppLocalizations.of(context);
      expect(find.text(l10n.deleteImpactBudgets(4)), findsOneWidget);
    });

    testWidgets(
        'ConfirmDeleteRootWithSubcategoriesSheet: budgetCount 0 no muestra '
        'ningún aviso', (tester) async {
      await tester.pumpAppWidget(
        const ConfirmDeleteRootWithSubcategoriesSheet(
          kind: CategoryKind.expense,
          rootId: 'root-1',
        ),
      );

      final noticeUnderSheet = find.descendant(
        of: find.byType(ConfirmDeleteRootWithSubcategoriesSheet),
        matching: find.byType(BudgetUsageNotice),
      );
      expect(noticeUnderSheet, findsOneWidget);
      expect(
        find.descendant(of: noticeUnderSheet, matching: find.byType(Text)),
        findsNothing,
      );
    });
  });
}

Widget _wrapWithTrigger({required void Function(BuildContext) onPressed}) {
  return MaterialApp(
    theme: AppTheme.light(),
    locale: const Locale('es'),
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: Builder(
      builder: (context) => Scaffold(
        body: Center(
          child: ElevatedButton(
            onPressed: () => onPressed(context),
            child: const Text('abrir'),
          ),
        ),
      ),
    ),
  );
}
