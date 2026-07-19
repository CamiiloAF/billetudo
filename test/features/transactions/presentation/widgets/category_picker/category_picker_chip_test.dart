import 'package:billetudo/core/theme/app_colors.dart';
import 'package:billetudo/core/theme/app_theme.dart';
import 'package:billetudo/features/categories/domain/entities/category.dart';
import 'package:billetudo/features/transactions/presentation/widgets/category_picker/category_picker_chip.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

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
        theme:
            brightness == Brightness.dark ? AppTheme.dark() : AppTheme.light(),
        home: Scaffold(body: child),
      );

  BoxDecoration wrapDecorationOf(WidgetTester tester) {
    final container = tester
        .widgetList<Container>(
          find.descendant(
            of: find.byType(CategoryPickerChip),
            matching: find.byType(Container),
          ),
        )
        .first;
    return container.decoration! as BoxDecoration;
  }

  testWidgets(
      'selected: fondo soft del color de la categoría, borde 2px del color '
      'sólido, texto textPrimary (light)', (tester) async {
    await tester.pumpWidget(
      appWith(CategoryPickerChip(category: ocio, selected: true, onTap: () {})),
    );

    final decoration = wrapDecorationOf(tester);
    expect(decoration.color, AppColors.light.mintSoft);
    expect(decoration.border, isA<Border>());
    expect(
      (decoration.border! as Border).top.color,
      AppColors.light.mint,
    );
    expect((decoration.border! as Border).top.width, 2);

    final label = tester.widget<Text>(find.text('Ocio'));
    expect(label.style?.color, AppColors.light.textPrimary);

    final icon = tester.widget<Icon>(find.byIcon(LucideIcons.partyPopper));
    expect(icon.color, AppColors.light.mint);
  });

  testWidgets(
      'unselected: fondo muted, sin borde, texto textSecondary, ícono con su '
      'propio color (light)', (tester) async {
    await tester.pumpWidget(
      appWith(
          CategoryPickerChip(category: ocio, selected: false, onTap: () {})),
    );

    final decoration = wrapDecorationOf(tester);
    expect(decoration.color, AppColors.light.muted);
    expect(decoration.border, isNull);

    final label = tester.widget<Text>(find.text('Ocio'));
    expect(label.style?.color, AppColors.light.textSecondary);

    final icon = tester.widget<Icon>(find.byIcon(LucideIcons.partyPopper));
    expect(icon.color, AppColors.light.mint);
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

    final decoration = wrapDecorationOf(tester);
    expect(decoration.color, AppColors.dark.mintSoft);
    expect(decoration.color, isNot(AppColors.light.mintSoft));

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

    final decoration = wrapDecorationOf(tester);
    expect(decoration.color, AppColors.dark.muted);
    expect(decoration.color, isNot(AppColors.light.muted));

    final label = tester.widget<Text>(find.text('Ocio'));
    expect(label.style?.color, AppColors.dark.textSecondary);
    expect(label.style?.color, isNot(AppColors.light.textSecondary));
  });
}
