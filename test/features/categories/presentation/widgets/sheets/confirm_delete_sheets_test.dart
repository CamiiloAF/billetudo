import 'package:billetudo/core/l10n/gen/app_localizations.dart';
import 'package:billetudo/core/theme/app_colors.dart';
import 'package:billetudo/core/theme/app_theme.dart';
import 'package:billetudo/core/widgets/bottom_sheet_base.dart';
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
        'icono trash-2 en tono violeta (nunca rojo), sin título, y las '
        '2 acciones', (
      tester,
    ) async {
      await tester.pumpAppWidget(const ConfirmDeleteSimpleSheet());

      // Reversible via papelera: icon + message only, no separate title, and
      // the icon/button stay violeta ($primary), never a destructive red.
      expect(
        find.textContaining('Podrás recuperarla luego desde la papelera'),
        findsOneWidget,
      );
      expect(find.text('Cancelar'), findsOneWidget);
      expect(find.text('Eliminar'), findsOneWidget);
      // Both the header icon and the confirm button's icon are trash2 — never
      // a destructive alert-triangle, and never the neutral `trash`.
      expect(find.byIcon(LucideIcons.trash2), findsNWidgets(2));
      expect(find.byIcon(LucideIcons.triangleAlert), findsNothing);
      expect(find.byIcon(LucideIcons.trash), findsNothing);

      final context = tester.element(find.byType(ConfirmDeleteSimpleSheet));
      final colors = context.colors;
      final sheetMessage = tester.widget<SheetMessage>(
        find.byType(SheetMessage),
      );
      expect(sheetMessage.iconColor, colors.primaryOnSoft);
      expect(sheetMessage.iconBackground, colors.primarySoft);
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
          categoryName: 'Restaurantes',
          transactionCount: 3,
          kind: CategoryKind.expense,
          excludingId: 'cat-1',
        ),
      );

      expect(
        find.textContaining('"Restaurantes" tiene 3 movimientos asociados'),
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
          categoryName: 'Restaurantes',
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
              categoryName: 'Restaurantes',
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
          categoryName: 'Transporte',
          subcategoryCount: 2,
          kind: CategoryKind.expense,
          rootId: 'root-1',
        ),
      );

      // `w9ixr`'s title is `enabled:false`: a single message with the real
      // category name and subcategory count interpolated, no separate title.
      expect(
        find.textContaining('"Transporte" tiene 2 subcategorías activas'),
        findsOneWidget,
      );
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
          categoryName: 'Transporte',
          subcategoryCount: 2,
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
          categoryName: 'Restaurantes',
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
          categoryName: 'Restaurantes',
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
          categoryName: 'Transporte',
          subcategoryCount: 2,
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
          categoryName: 'Transporte',
          subcategoryCount: 2,
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
