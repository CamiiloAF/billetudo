import 'package:billetudo/core/l10n/gen/app_localizations.dart';
import 'package:billetudo/features/home/domain/entities/home_ai_insight.dart';
import 'package:billetudo/features/home/presentation/widgets/ai_card.dart';
import 'package:billetudo/features/home/presentation/widgets/ai_question_chip.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'pump_widget.dart';

/// Criterio 10: la card de IA resuelve 4 variantes desde `HomeAiInsight?`
/// (chips / insight sin cola / insight con cola / insight forzado
/// "crea un presupuesto"). Criterio 11: el chip/CTA "Ayúdame a presupuestar"
/// nunca llama a `onAskQuestion` — siempre navega directo.
void main() {
  Widget card({
    HomeAiInsight? insight,
    ValueChanged<String?>? onAskQuestion,
    VoidCallback? onCreateBudget,
    VoidCallback? onDismissInsight,
    ValueChanged<String>? onStartInsightConversation,
    ValueChanged<String>? onContinueInsightConversation,
  }) =>
      AiCard(
        insight: insight,
        onAskQuestion: onAskQuestion ?? (_) {},
        onCreateBudget: onCreateBudget ?? () {},
        onDismissInsight: onDismissInsight,
        onStartInsightConversation: onStartInsightConversation ?? (_) {},
        onContinueInsightConversation:
            onContinueInsightConversation ?? (_) {},
      );

  group('sin insight: variante "con chips" (default, sin importar acceso)', () {
    testWidgets('muestra 4 AiQuestionChip, el 4to "Ayúdame a presupuestar"',
        (tester) async {
      await tester.pumpHomeWidget(card());
      final l10n = AppLocalizations.of(tester.element(find.byType(AiCard)));

      expect(find.byType(AiQuestionChip), findsNWidgets(4));
      expect(find.text(l10n.homeAiChipBudgetHelp), findsOneWidget);
    });

    testWidgets(
        'criterio 11: tocar el chip "Ayúdame a presupuestar" invoca '
        'onCreateBudget directo, nunca onAskQuestion', (tester) async {
      // The 4th chip sits past the fold of the chips' horizontal scroller at
      // the default 800×600 test surface — widen it so the tap actually
      // lands on the chip instead of empty space off to its right.
      tester.view.physicalSize = const Size(1400, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      var createBudgetTapped = 0;
      var askQuestionTapped = 0;
      await tester.pumpHomeWidget(
        card(
          onCreateBudget: () => createBudgetTapped++,
          onAskQuestion: (_) => askQuestionTapped++,
        ),
      );
      final l10n = AppLocalizations.of(tester.element(find.byType(AiCard)));

      await tester.tap(find.text(l10n.homeAiChipBudgetHelp));
      await tester.pump();

      expect(createBudgetTapped, 1);
      expect(askQuestionTapped, 0);
    });

    testWidgets(
        'tocar un chip de conversación invoca onAskQuestion con su '
        'propia pregunta', (tester) async {
      String? asked;
      await tester.pumpHomeWidget(card(onAskQuestion: (q) => asked = q));
      final l10n = AppLocalizations.of(tester.element(find.byType(AiCard)));

      await tester.tap(find.text(l10n.homeAiChipMonthProgress));
      await tester.pump();

      expect(asked, l10n.homeAiChipMonthProgress);
    });

    testWidgets('tocar el cuerpo de la card invoca onAskQuestion(null)',
        (tester) async {
      String? asked = 'not-called';
      var called = false;
      await tester.pumpHomeWidget(
        card(onAskQuestion: (q) {
          asked = q;
          called = true;
        }),
      );
      final l10n = AppLocalizations.of(tester.element(find.byType(AiCard)));

      await tester.tap(find.text(l10n.homeAiCardTitle));
      await tester.pump();

      expect(called, isTrue);
      expect(asked, isNull);
    });
  });

  group(
      'bugfix item 7: el chip de un insight distingue "iniciar" de '
      '"continuar" según HomeAiInsight.conversationId', () {
    testWidgets(
        'sin conversationId: muestra el chip específico del insight (no '
        'genérico) y tocarlo invoca onStartInsightConversation con una '
        'pregunta real (nunca el texto del propio botón), nunca '
        'onContinueInsightConversation', (tester) async {
      const insight = HomeAiInsight(
        type: HomeAiInsightType.spendingVsAverage,
        percentDelta: 15,
      );
      String? started;
      var continued = 0;
      await tester.pumpHomeWidget(
        card(
          insight: insight,
          onStartInsightConversation: (q) => started = q,
          onContinueInsightConversation: (_) => continued++,
        ),
      );
      final l10n = AppLocalizations.of(tester.element(find.byType(AiCard)));

      expect(find.text(l10n.homeAiInsightAverageUpChip), findsOneWidget);
      expect(find.text(l10n.homeAiInsightContinueChip), findsNothing);

      await tester.tap(find.text(l10n.homeAiInsightAverageUpChip));
      await tester.pump();

      expect(started, l10n.homeAiInsightAverageUpQuestion);
      expect(continued, 0);
    });

    testWidgets(
        'con conversationId: muestra "continuar conversación" y tocarlo '
        'invoca onContinueInsightConversation con ese id exacto, nunca '
        'onStartInsightConversation', (tester) async {
      const insight = HomeAiInsight(
        type: HomeAiInsightType.spendingVsAverage,
        percentDelta: 15,
        conversationId: 'conv-linked',
      );
      String? continuedId;
      var started = 0;
      await tester.pumpHomeWidget(
        card(
          insight: insight,
          onContinueInsightConversation: (id) => continuedId = id,
          onStartInsightConversation: (_) => started++,
        ),
      );
      final l10n = AppLocalizations.of(tester.element(find.byType(AiCard)));

      expect(find.text(l10n.homeAiInsightContinueChip), findsOneWidget);
      expect(find.text(l10n.homeAiInsightAverageUpChip), findsNothing);

      await tester.tap(find.text(l10n.homeAiInsightContinueChip));
      await tester.pump();

      expect(continuedId, 'conv-linked');
      expect(started, 0);
    });
  });

  group('con insight sin cola', () {
    testWidgets('muestra el link "Ahora no" y ningún contador "1 de N"',
        (tester) async {
      const insight = HomeAiInsight(
        type: HomeAiInsightType.spendingVsAverage,
        percentDelta: 15,
      );
      await tester
          .pumpHomeWidget(card(insight: insight, onDismissInsight: () {}));
      final l10n = AppLocalizations.of(tester.element(find.byType(AiCard)));

      expect(find.text(l10n.homeAiInsightDismiss), findsOneWidget);
      expect(find.textContaining('1 de'), findsNothing);
    });

    testWidgets('tocar "Ahora no" invoca onDismissInsight', (tester) async {
      var tapped = 0;
      const insight = HomeAiInsight(
        type: HomeAiInsightType.spendingVsAverage,
        percentDelta: 15,
      );
      await tester.pumpHomeWidget(
        card(insight: insight, onDismissInsight: () => tapped++),
      );
      final l10n = AppLocalizations.of(tester.element(find.byType(AiCard)));

      await tester.tap(find.text(l10n.homeAiInsightDismiss));
      await tester.pump();

      expect(tapped, 1);
    });
  });

  testWidgets(
      'criterio 10: con >=2 insights en cola, agrega el contador "1 de N"',
      (tester) async {
    const insight = HomeAiInsight(
      type: HomeAiInsightType.spendingVsAverage,
      percentDelta: 15,
      queuePosition: 1,
      queueLength: 3,
    );
    await tester.pumpHomeWidget(card(insight: insight));
    final l10n = AppLocalizations.of(tester.element(find.byType(AiCard)));

    expect(find.text(l10n.homeAiInsightQueueCounter(1, 3)), findsOneWidget);
  });

  group(
      'criterio 10: estado hero "sin presupuesto" fuerza el insight '
      '"crea un presupuesto"', () {
    testWidgets(
        'icono gauge, sin "Ahora no" (no se puede descartar), CTA '
        'directa', (tester) async {
      tester.view.physicalSize = const Size(1400, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      const insight = HomeAiInsight.createBudget();
      var createBudgetTapped = 0;
      var askQuestionTapped = 0;
      await tester.pumpHomeWidget(
        card(
          insight: insight,
          onCreateBudget: () => createBudgetTapped++,
          onAskQuestion: (_) => askQuestionTapped++,
          // Even if the caller wires a dismiss handler, the createBudget
          // insight never renders "Ahora no" — there is nothing to dismiss
          // into (it's not part of a queue with other kinds).
          onDismissInsight: () {},
        ),
      );
      final l10n = AppLocalizations.of(tester.element(find.byType(AiCard)));

      expect(find.byIcon(LucideIcons.gauge), findsOneWidget);
      expect(find.text(l10n.homeAiInsightDismiss), findsNothing);
      expect(find.text(l10n.homeAiChipBudgetHelp), findsOneWidget);

      await tester.tap(find.text(l10n.homeAiChipBudgetHelp));
      await tester.pump();

      expect(createBudgetTapped, 1);
      expect(askQuestionTapped, 0);
    });
  });

  testWidgets('tema oscuro: renderiza ambas variantes sin excepción (HU-11)',
      (tester) async {
    await tester.pumpHomeWidget(card(), brightness: Brightness.dark);
    expect(tester.takeException(), isNull);

    await tester.pumpHomeWidget(
      card(
        insight: const HomeAiInsight(
          type: HomeAiInsightType.spendingVsAverage,
          percentDelta: 15,
        ),
      ),
      brightness: Brightness.dark,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets(
      'a un ancho de teléfono real (390px), la variante "con insight" (no '
      'createBudget) no desborda su Row de chip "Continuar" + botón "Ahora '
      'no" (regresión: ai_question_chip.dart no dejaba espacio suficiente '
      'para ambos)', (tester) async {
    tester.view.physicalSize = const Size(390, 844) * 3;
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    await tester.pumpHomeWidget(
      Padding(
        padding: const EdgeInsets.all(20),
        child: card(
          insight: const HomeAiInsight(
            type: HomeAiInsightType.spendingVsAverage,
            percentDelta: 22,
          ),
          onDismissInsight: () {},
        ),
      ),
    );
    await tester.pump();

    expect(
      tester.takeException(),
      isNull,
      reason: 'ai_question_chip.dart shrinks the "Continuar" label to the '
          'space actually left by the "Ahora no" button instead of '
          'insisting on a fixed 200px width regardless of the available '
          'space',
    );
  });
}
