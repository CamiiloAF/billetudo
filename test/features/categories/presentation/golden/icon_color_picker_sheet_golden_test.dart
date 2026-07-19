import 'package:billetudo/features/categories/presentation/widgets/icon_color_picker_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../support/golden_helpers.dart';

/// `ParentCategoryPickerSheet` is deliberately not covered here: unlike this
/// sheet, it resolves its cubit through `getIt` (see
/// `ParentCategoryPickerSheet.build`), which would require standing up the
/// feature's whole DI graph just to render a golden. `IconColorPickerSheet`
/// has no such dependency, so it is the one picker cheap enough to golden in
/// isolation.
void main() {
  setUpAll(() async {
    disableGoogleFontsRuntimeFetching();
    await loadMaterialIconsFont();
  });

  Future<void> golden(
    WidgetTester tester,
    String name, {
    required Brightness brightness,
    String? initialIcon,
    String? initialColor,
  }) async {
    setGoldenViewport(tester);
    await tester.pumpWidget(
      wrapForGolden(
        Builder(
          builder: (context) => ElevatedButton(
            onPressed: () => IconColorPickerSheet.show(
              context,
              initialIcon: initialIcon,
              initialColor: initialColor,
            ),
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
      matchesGoldenFile('goldens/sheet_icon_color_picker_$name.png'),
    );
  }

  for (final brightness in Brightness.values) {
    final suffix = brightness == Brightness.light ? 'light' : 'dark';

    testWidgets('empty selection, defaults to first icon/color ($suffix)',
        (tester) async {
      await golden(tester, 'empty_$suffix', brightness: brightness);
    });

    testWidgets('with an icon/color already selected ($suffix)',
        (tester) async {
      await golden(
        tester,
        'selected_$suffix',
        brightness: brightness,
        initialIcon: 'car',
        initialColor: 'sky',
      );
    });
  }
}
