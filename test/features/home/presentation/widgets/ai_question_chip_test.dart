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
}
