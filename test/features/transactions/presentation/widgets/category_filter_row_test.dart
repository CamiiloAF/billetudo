import 'package:billetudo/core/l10n/gen/app_localizations.dart';
import 'package:billetudo/core/theme/app_colors.dart';
import 'package:billetudo/core/theme/app_theme.dart';
import 'package:billetudo/features/categories/domain/entities/category.dart';
import 'package:billetudo/features/transactions/presentation/widgets/sheets/category_filter_row.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final category = Category(
    id: 'cat-1',
    name: 'Comida',
    kind: CategoryKind.expense,
    sortOrder: 0,
    createdAt: DateTime(2026, 7, 15),
    updatedAt: DateTime(2026, 7, 15).millisecondsSinceEpoch,
  );

  Widget appWith(Widget child) => MaterialApp(
        theme: AppTheme.light(),
        locale: const Locale('es'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(body: child),
      );

  testWidgets('no muestra ícono de check en ningún estado (q0CTl/NZbsD)',
      (tester) async {
    await tester.pumpWidget(
      appWith(
        CategoryFilterRow(
          category: category,
          selected: true,
          onToggleSelected: () {},
        ),
      ),
    );

    expect(find.byIcon(Icons.check), findsNothing);
  });

  testWidgets('seleccionada: adopta el fill/stroke primary-soft/primary',
      (tester) async {
    await tester.pumpWidget(
      appWith(
        CategoryFilterRow(
          category: category,
          selected: true,
          onToggleSelected: () {},
        ),
      ),
    );

    final material = tester.widget<Material>(
      find
          .descendant(
            of: find.byType(CategoryFilterRow),
            matching: find.byType(Material),
          )
          .first,
    );
    expect(material.color, AppColors.light.primarySoft);
  });

  testWidgets('tocar el cuerpo de la fila selecciona, no abre el chevron',
      (tester) async {
    var selectedTaps = 0;
    var expandTaps = 0;
    await tester.pumpWidget(
      appWith(
        CategoryFilterRow(
          category: category,
          selected: false,
          subcategoryCount: 2,
          onToggleSelected: () => selectedTaps++,
          onToggleExpand: () => expandTaps++,
        ),
      ),
    );

    await tester.tap(find.text('Comida'));
    expect(selectedTaps, 1);
    expect(expandTaps, 0);

    await tester.tap(find.byType(IconButton));
    expect(expandTaps, 1);
    expect(selectedTaps, 1);
  });

  testWidgets('una subcategoría no muestra contador ni chevron',
      (tester) async {
    await tester.pumpWidget(
      appWith(
        CategoryFilterRow(
          category: category,
          selected: false,
          isSubcategory: true,
          onToggleSelected: () {},
        ),
      ),
    );

    expect(find.byType(IconButton), findsNothing);
  });
}
