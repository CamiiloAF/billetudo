import 'package:billetudo/core/theme/app_colors.dart';
import 'package:billetudo/core/theme/app_theme.dart';
import 'package:billetudo/features/scheduled_payments/presentation/widgets/scheduled_count_pill.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Widget appWith(Widget child) => MaterialApp(
        theme: AppTheme.light(),
        home: Scaffold(body: child),
      );

  testWidgets(
      'emphasized=true uses primarySoft background and primaryOnSoftStrong text',
      (tester) async {
    await tester.pumpWidget(
      appWith(const ScheduledCountPill(label: 'Activos · 3', emphasized: true)),
    );

    final container = tester.widget<Container>(find.byType(Container));
    final decoration = container.decoration! as BoxDecoration;
    expect(decoration.color, AppColors.light.primarySoft);

    final text = tester.widget<Text>(find.text('Activos · 3'));
    expect(text.style?.color, AppColors.light.primaryOnSoftStrong);
  });

  testWidgets(
      'el seleccionado lleva borde primaryOnSoftStrong 1.5 hacia dentro: sin '
      'él el estado se cifraría solo en el color del label', (tester) async {
    await tester.pumpWidget(
      appWith(const ScheduledCountPill(label: 'Activos · 3', emphasized: true)),
    );

    final container = tester.widget<Container>(find.byType(Container));
    final border = (container.decoration! as BoxDecoration).border!.top;
    expect(border.color, AppColors.light.primaryOnSoftStrong);
    expect(border.width, 1.5);
    expect(border.strokeAlign, BorderSide.strokeAlignInside);
  });

  testWidgets(
      'tema oscuro: el borde resuelve primaryOnSoftStrong de AppColors.dark '
      '(primary crudo daría 2.75:1 sobre muted)', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.dark(),
        home: const Scaffold(
          body: ScheduledCountPill(label: 'Activos · 3', emphasized: true),
        ),
      ),
    );

    final container = tester.widget<Container>(find.byType(Container));
    final border = (container.decoration! as BoxDecoration).border!.top;
    expect(border.color, AppColors.dark.primaryOnSoftStrong);
    expect(border.color, isNot(AppColors.dark.primary));
  });

  testWidgets('el inactivo no lleva borde', (tester) async {
    await tester.pumpWidget(
      appWith(
          const ScheduledCountPill(label: 'Terminados · 5', emphasized: false)),
    );

    final container = tester.widget<Container>(find.byType(Container));
    expect((container.decoration! as BoxDecoration).border, isNull);
  });

  testWidgets('emphasized=false uses muted background and textSecondary text',
      (tester) async {
    await tester.pumpWidget(
      appWith(
          const ScheduledCountPill(label: 'Terminados · 5', emphasized: false)),
    );

    final container = tester.widget<Container>(find.byType(Container));
    final decoration = container.decoration! as BoxDecoration;
    expect(decoration.color, AppColors.light.muted);

    final text = tester.widget<Text>(find.text('Terminados · 5'));
    expect(text.style?.color, AppColors.light.textSecondary);
  });
}
