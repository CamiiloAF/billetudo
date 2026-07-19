import 'package:billetudo/features/categories/domain/entities/category.dart';
import 'package:billetudo/features/categories/presentation/widgets/sheets/confirm_delete_root_with_subcategories_sheet.dart';
import 'package:billetudo/features/categories/presentation/widgets/sheets/confirm_delete_simple_sheet.dart';
import 'package:billetudo/features/categories/presentation/widgets/sheets/confirm_delete_with_transactions_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../support/golden_helpers.dart';

void main() {
  setUpAll(() async {
    disableGoogleFontsRuntimeFetching();
    await loadMaterialIconsFont();
  });

  /// Opens [openSheet] through a real trigger button (mirrors how a sheet
  /// actually reaches the screen — scrim, drag handle and the bottom sheet
  /// theme included) and captures the whole screen, same pattern as
  /// Accounts' `sheets_golden_test.dart`.
  Future<void> golden(
    WidgetTester tester,
    Future<void> Function(BuildContext context) openSheet,
    String name, {
    required Brightness brightness,
  }) async {
    setGoldenViewport(tester);
    await tester.pumpWidget(
      wrapForGolden(
        Builder(
          builder: (context) => ElevatedButton(
            onPressed: () => openSheet(context),
            child: const Text('open'),
          ),
        ),
        brightness: brightness,
      ),
    );
    await tester.tap(find.byType(ElevatedButton));
    await tester.pumpAndSettle();
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/sheet_$name.png'),
    );
  }

  for (final brightness in Brightness.values) {
    final suffix = brightness == Brightness.light ? 'light' : 'dark';

    testWidgets('confirm delete, simple (no dependents) ($suffix)',
        (tester) async {
      await golden(
        tester,
        ConfirmDeleteSimpleSheet.show,
        'confirm_delete_simple_$suffix',
        brightness: brightness,
      );
    });

    testWidgets('confirm delete, with transactions ($suffix)',
        (tester) async {
      await golden(
        tester,
        (context) => ConfirmDeleteWithTransactionsSheet.show(
          context,
          transactionCount: 3,
          kind: CategoryKind.expense,
          excludingId: 'cat-1',
        ),
        'confirm_delete_with_transactions_$suffix',
        brightness: brightness,
      );
    });

    testWidgets('confirm delete, root with active subcategories ($suffix)',
        (tester) async {
      await golden(
        tester,
        (context) => ConfirmDeleteRootWithSubcategoriesSheet.show(
          context,
          kind: CategoryKind.expense,
          rootId: 'root-1',
        ),
        'confirm_delete_root_with_subcategories_$suffix',
        brightness: brightness,
      );
    });
  }
}
