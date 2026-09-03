import 'package:billetudo/features/home/presentation/widgets/ai_card_chips.dart';
import 'package:billetudo/features/home/presentation/widgets/ai_question_chip.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'pump_widget.dart';

/// Issue #22's "regla de altura dinámica por fila"
/// (`design-system/billetudo/pages/inicio.md`): the 4 suggested-question
/// chips prefer 1 line (44px), but `IntrinsicHeight` + `CrossAxisAlignment
/// .stretch` make every chip in the row share the tallest chip's height —
/// never mixed heights — even though `AiQuestionChip.maxLines` is now 2 and
/// each chip's own label can wrap independently.
void main() {
  testWidgets(
      'los 4 chips comparten la misma altura, aunque solo alguno '
      'necesite 2 líneas', (tester) async {
    await tester.pumpHomeWidget(
      AiCardChips(
        budgetChipIsDirectNav: false,
        onAskQuestion: (_) {},
        onCreateBudget: () {},
      ),
    );

    final chipFinder = find.byType(AiQuestionChip);
    expect(chipFinder, findsNWidgets(4));

    final heights = chipFinder
        .evaluate()
        .map((element) => tester.getSize(find.byWidget(element.widget)).height)
        .toSet();

    expect(heights.length, 1);
  });

  testWidgets('renderiza sin excepción en tema oscuro', (tester) async {
    await tester.pumpHomeWidget(
      AiCardChips(
        budgetChipIsDirectNav: false,
        onAskQuestion: (_) {},
        onCreateBudget: () {},
      ),
      brightness: Brightness.dark,
    );

    expect(tester.takeException(), isNull);
  });
}
