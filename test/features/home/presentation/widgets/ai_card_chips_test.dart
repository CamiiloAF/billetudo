import 'package:billetudo/features/home/presentation/widgets/ai_card_chips.dart';
import 'package:billetudo/features/home/presentation/widgets/ai_question_chip.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'pump_widget.dart';

/// The 4 suggested-question chips share a forced uniform height
/// (`_chipHeight`), regardless of how many lines their own label would need
/// on its own — every chip's label is truncated to a single line
/// (`AiQuestionChip.maxLines: 1`), so the row reads level.
void main() {
  testWidgets('los 4 chips comparten la misma altura fija', (tester) async {
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
