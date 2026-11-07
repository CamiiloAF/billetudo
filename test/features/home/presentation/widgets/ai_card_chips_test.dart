import 'package:billetudo/core/l10n/gen/app_localizations.dart';
import 'package:billetudo/features/home/presentation/widgets/ai_card_chips.dart';
import 'package:billetudo/features/home/presentation/widgets/ai_question_chip.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'pump_widget.dart';

/// The Home AI card's no-insight variant. The 4 suggested-question chips were
/// removed by product request (2026-11-07): the card is now its compact header
/// (orb + copy + chevron) and the whole body opens the assistant. These tests
/// pin that removal, because the old chip tests no longer describe the card.
void main() {
  Widget chips({ValueChanged<String?>? onAskQuestion}) => AiCardChips(
        budgetChipIsDirectNav: false,
        onAskQuestion: onAskQuestion ?? (_) {},
        onCreateBudget: () {},
      );

  testWidgets('ya no renderiza la fila de chips: solo el header',
      (tester) async {
    await tester.pumpHomeWidget(chips());

    final l10n = AppLocalizations.of(
      tester.element(find.byType(AiCardChips)),
    );

    expect(find.byType(AiQuestionChip), findsNothing);
    expect(find.text(l10n.homeAiCardTitle), findsOneWidget);
    expect(find.text(l10n.homeAiCardSubtitle), findsOneWidget);
  });

  testWidgets('tocar el cuerpo invoca onAskQuestion(null), no una pregunta',
      (tester) async {
    String? asked = 'not-called';
    var called = false;
    await tester.pumpHomeWidget(
      chips(onAskQuestion: (question) {
        asked = question;
        called = true;
      }),
    );

    final l10n = AppLocalizations.of(
      tester.element(find.byType(AiCardChips)),
    );
    await tester.tap(find.text(l10n.homeAiCardTitle));
    await tester.pump();

    expect(called, isTrue);
    expect(asked, isNull);
  });

  testWidgets('renderiza sin excepción en tema oscuro', (tester) async {
    await tester.pumpHomeWidget(chips(), brightness: Brightness.dark);

    expect(tester.takeException(), isNull);
  });
}
