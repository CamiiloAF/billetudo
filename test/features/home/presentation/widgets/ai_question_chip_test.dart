import 'package:billetudo/core/theme/app_colors.dart';
import 'package:billetudo/features/home/presentation/widgets/ai_question_chip.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'pump_widget.dart';

/// Criterio 11: `arrow-right` recto (nunca `arrow-up-right` diagonal) para el
/// chip de navegación directa, distinguiéndolo visualmente de los chips de
/// conversación.
void main() {
  testWidgets('isDirectNav=false (default): icono arrow-up-right diagonal',
      (tester) async {
    await tester.pumpHomeWidget(
      AiQuestionChip(label: 'Pregunta', onTap: () {}),
    );

    expect(find.byIcon(LucideIcons.arrowUpRight), findsOneWidget);
    expect(find.byIcon(LucideIcons.arrowRight), findsNothing);
  });

  testWidgets(
      'criterio 11: isDirectNav=true ("Ayúdame a presupuestar"): icono '
      'arrow-right recto, nunca diagonal', (tester) async {
    await tester.pumpHomeWidget(
      AiQuestionChip(
          label: 'Ayúdame a presupuestar', isDirectNav: true, onTap: () {}),
    );

    expect(find.byIcon(LucideIcons.arrowRight), findsOneWidget);
    expect(find.byIcon(LucideIcons.arrowUpRight), findsNothing);
  });

  testWidgets('tocar el chip dispara onTap', (tester) async {
    var tapped = 0;
    await tester.pumpHomeWidget(
      AiQuestionChip(label: 'Pregunta', onTap: () => tapped++),
    );

    await tester.tap(find.byType(AiQuestionChip));
    await tester.pump();

    expect(tapped, 1);
  });

  testWidgets('tema oscuro: renderiza sin excepción (HU-11)', (tester) async {
    await tester.pumpHomeWidget(
      AiQuestionChip(label: 'Pregunta', onTap: () {}),
      brightness: Brightness.dark,
    );

    expect(tester.takeException(), isNull);
  });

  testWidgets('tema oscuro: fondo usa AppColors.muted; icono usa primaryOnSoft',
      (tester) async {
    await tester.pumpHomeWidget(
      AiQuestionChip(label: 'Pregunta', onTap: () {}),
      brightness: Brightness.dark,
    );

    final material = tester.widget<Material>(
      find.descendant(
        of: find.byType(AiQuestionChip),
        matching: find.byType(Material),
      ),
    );
    expect(material.color, AppColors.dark.muted);

    final icon = tester.widget<Icon>(find.byIcon(LucideIcons.arrowUpRight));
    expect(icon.color, AppColors.dark.primaryOnSoft);
  });

  testWidgets('tema claro: fondo usa AppColors.muted; icono usa primaryOnSoft',
      (tester) async {
    await tester.pumpHomeWidget(
      AiQuestionChip(label: 'Pregunta', onTap: () {}),
    );

    final material = tester.widget<Material>(
      find.descendant(
        of: find.byType(AiQuestionChip),
        matching: find.byType(Material),
      ),
    );
    expect(material.color, AppColors.light.muted);

    final icon = tester.widget<Icon>(find.byIcon(LucideIcons.arrowUpRight));
    expect(icon.color, AppColors.light.primaryOnSoft);
  });

  testWidgets('etiqueta larga se trunca en una sola línea (maxLines: 1)',
      (tester) async {
    await tester.pumpHomeWidget(
      AiQuestionChip(
        label: '¿Cuánto llevo ahorrado en mis metas?',
        onTap: () {},
      ),
    );

    final text = tester.widget<Text>(
      find.descendant(
        of: find.byType(AiQuestionChip),
        matching: find.byType(Text),
      ),
    );
    expect(text.maxLines, 1);
    expect(text.overflow, TextOverflow.ellipsis);
  });

  testWidgets('padding uniforme de 14 en los cuatro lados', (tester) async {
    await tester.pumpHomeWidget(
      AiQuestionChip(label: 'Pregunta', onTap: () {}),
    );

    final container = tester.widget<Container>(
      find.descendant(
        of: find.byType(AiQuestionChip),
        matching: find.byType(Container),
      ),
    );
    expect(container.padding, const EdgeInsets.all(14));
  });
}
