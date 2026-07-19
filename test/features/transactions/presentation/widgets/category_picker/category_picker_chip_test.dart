import 'package:billetudo/core/theme/app_colors.dart';
import 'package:billetudo/core/theme/app_theme.dart';
import 'package:billetudo/features/categories/domain/entities/category.dart';
import 'package:billetudo/features/transactions/presentation/widgets/category_picker/category_picker_chip.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final ocio = Category(
    id: 'cat-1',
    name: 'Ocio',
    kind: CategoryKind.expense,
    icon: 'party-popper',
    color: 'mint',
    sortOrder: 0,
    createdAt: DateTime(2026),
    updatedAt: 0,
  );

  Widget appWith(Widget child, {Brightness brightness = Brightness.light}) =>
      MaterialApp(
        theme: brightness == Brightness.dark ? AppTheme.dark() : AppTheme.light(),
        home: Scaffold(body: child),
      );

  testWidgets('selected: fondo primarySoft/borde primary/texto textPrimary (light)',
      (tester) async {
    await tester.pumpWidget(
      appWith(CategoryPickerChip(category: ocio, selected: true, onTap: () {})),
    );

    final material = tester.widget<Material>(
      find.descendant(
        of: find.byType(CategoryPickerChip),
        matching: find.byType(Material),
      ),
    );
    expect(material.color, AppColors.light.primarySoft);

    final label = tester.widget<Text>(find.text('Ocio'));
    expect(label.style?.color, AppColors.light.textPrimary);
  });

  testWidgets('unselected: fondo surface/texto textSecondary (light)', (tester) async {
    await tester.pumpWidget(
      appWith(CategoryPickerChip(category: ocio, selected: false, onTap: () {})),
    );

    final material = tester.widget<Material>(
      find.descendant(
        of: find.byType(CategoryPickerChip),
        matching: find.byType(Material),
      ),
    );
    expect(material.color, AppColors.light.surface);

    final label = tester.widget<Text>(find.text('Ocio'));
    expect(label.style?.color, AppColors.light.textSecondary);
  });

  testWidgets('tocar el chip dispara onTap una vez', (tester) async {
    var tapCount = 0;
    await tester.pumpWidget(
      appWith(
        CategoryPickerChip(
          category: ocio,
          selected: false,
          onTap: () => tapCount++,
        ),
      ),
    );

    await tester.tap(find.byType(CategoryPickerChip));
    await tester.pump();

    expect(tapCount, 1);
  });

  testWidgets(
      'tema oscuro, selected: fondo/texto resuelven AppColors.dark, no los de light',
      (tester) async {
    await tester.pumpWidget(
      appWith(
        CategoryPickerChip(category: ocio, selected: true, onTap: () {}),
        brightness: Brightness.dark,
      ),
    );

    final material = tester.widget<Material>(
      find.descendant(
        of: find.byType(CategoryPickerChip),
        matching: find.byType(Material),
      ),
    );
    expect(material.color, AppColors.dark.primarySoft);
    expect(material.color, isNot(AppColors.light.primarySoft));

    final label = tester.widget<Text>(find.text('Ocio'));
    expect(label.style?.color, AppColors.dark.textPrimary);
    expect(label.style?.color, isNot(AppColors.light.textPrimary));
  });

  testWidgets(
      'tema oscuro, unselected: fondo/texto resuelven AppColors.dark, no los de light',
      (tester) async {
    await tester.pumpWidget(
      appWith(
        CategoryPickerChip(category: ocio, selected: false, onTap: () {}),
        brightness: Brightness.dark,
      ),
    );

    final material = tester.widget<Material>(
      find.descendant(
        of: find.byType(CategoryPickerChip),
        matching: find.byType(Material),
      ),
    );
    expect(material.color, AppColors.dark.surface);
    expect(material.color, isNot(AppColors.light.surface));

    final label = tester.widget<Text>(find.text('Ocio'));
    expect(label.style?.color, AppColors.dark.textSecondary);
    expect(label.style?.color, isNot(AppColors.light.textSecondary));
  });
}
