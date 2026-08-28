import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/l10n/gen/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/bottom_sheet_base.dart';
import '../../domain/entities/home_ai_insight.dart';
import 'ai_card_chips.dart';
import 'ai_card_insight.dart';

/// Home's slot-2 AI card (`design-system/billetudo/pages/inicio.md` § "Card
/// de IA — chrome condicional"): shown only with at least one transaction
/// (the caller never mounts it in the empty state), it resizes to what it
/// can honestly offer — chips, one insight, or a queued insight — never a
/// fixed shell around empty content.
///
/// Gate: tapping the card body or any conversation chip when the user has no
/// chat access opens the "Conversación en beta" sheet **at the moment of the
/// tap**, never before. The "Ayúdame a presupuestar" chip/CTA never shows
/// that sheet — [onCreateBudget] is the caller's own decision (dogfooding
/// fix: with chat access it opens a seeded conversation instead of the raw
/// form; the direct new-budget nav is the Nivel 0 fallback for everyone
/// else, never a wall).
class AiCard extends StatelessWidget {
  const AiCard({
    required this.insight,
    required this.onAskQuestion,
    required this.onCreateBudget,
    required this.onStartInsightConversation,
    required this.onContinueInsightConversation,
    this.onDismissInsight,
    super.key,
  });

  /// The insight to show, or `null` for the "con chips" default variant.
  final HomeAiInsight? insight;

  /// Opens the chat, already gated: the caller checks chat access first and
  /// shows [AiBetaSheet] instead when it is missing. `question` seeds the
  /// composer/first message when tapping a specific chip; `null` opens an
  /// empty conversation (tapping the card body).
  final ValueChanged<String?> onAskQuestion;

  /// Never shows the beta-upsell sheet (criterion 11) — but unlike the
  /// conversation chips, what it actually does is the caller's call: with
  /// chat access, opens a seeded conversation instead of the raw form
  /// (dogfooding fix); without it, the direct new-budget nav stays the
  /// unconditional Nivel 0 fallback.
  final VoidCallback onCreateBudget;

  /// The insight variant's own chip when it has no linked conversation yet
  /// (`HomeAiInsight.conversationId == null`): starts a brand-new thread
  /// seeded with the given question, and links it to this insight
  /// (bugfix item 7).
  final ValueChanged<String> onStartInsightConversation;

  /// The insight variant's own chip once it has a linked conversation:
  /// reopens that exact thread, never whatever conversation is most recently
  /// active in general (bugfix item 7).
  final ValueChanged<String> onContinueInsightConversation;

  /// "Ahora no": dismisses the current insight, revealing the next queued
  /// one (or the chips variant once the queue empties). `null` when there is
  /// no insight to dismiss.
  final VoidCallback? onDismissInsight;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final insight = this.insight;

    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(minHeight: 137),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.colors.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
        border: Border.all(color: context.colors.border),
      ),
      child: insight == null
          ? AiCardChips(
              onAskQuestion: onAskQuestion,
              onCreateBudget: onCreateBudget,
            )
          : AiCardInsight(
              insight: insight,
              onAskQuestion: onAskQuestion,
              onCreateBudget: onCreateBudget,
              onDismiss: onDismissInsight,
              onStartConversation: onStartInsightConversation,
              onContinueConversation: onContinueInsightConversation,
              l10n: l10n,
            ),
    );
  }
}

/// The "Conversación en beta" gate (`ytvPw`/`VxGME`): appears only at the
/// moment of the tap, never as a Home interruption. The card/chips
/// themselves render identically for every user — only the conversation is
/// restricted.
class AiBetaSheet extends StatelessWidget {
  const AiBetaSheet({super.key});

  static Future<void> show(BuildContext context) => BottomSheetBase.show<void>(
        context,
        builder: (context) => const AiBetaSheet(),
      );

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            color: colors.primarySoft,
            shape: BoxShape.circle,
          ),
          child:
              Icon(LucideIcons.sparkles, color: colors.primaryOnSoft, size: 30),
        ),
        const SizedBox(height: 16),
        Text(
          l10n.homeAiBetaSheetTitle,
          textAlign: TextAlign.center,
          style:
              theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 8),
        Text(
          l10n.homeAiBetaSheetMessage,
          textAlign: TextAlign.center,
          style:
              theme.textTheme.bodyMedium?.copyWith(color: colors.textSecondary),
        ),
        const SizedBox(height: 8),
        Text(
          l10n.homeAiDisclaimer,
          textAlign: TextAlign.center,
          style:
              theme.textTheme.bodySmall?.copyWith(color: colors.textSecondary),
        ),
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          child: FilledButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(l10n.comingSoonUnderstood),
          ),
        ),
      ],
    );
  }
}
