import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/l10n/gen/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/money_formatter.dart';
import '../../domain/entities/home_ai_insight.dart';
import 'ai_question_chip.dart';

/// The insight variants of `AiCard` (`Ih1x4`/`lKQ3p`/`GmKkQ`): "Ahora no"
/// replaces the old dismiss-`x`, plus an optional "1 de N" counter only when
/// queued.
class AiCardInsight extends StatelessWidget {
  const AiCardInsight({
    required this.insight,
    required this.onAskQuestion,
    required this.onCreateBudget,
    required this.onDismiss,
    required this.onStartConversation,
    required this.onContinueConversation,
    required this.l10n,
    super.key,
  });

  final HomeAiInsight insight;
  final ValueChanged<String?> onAskQuestion;
  final VoidCallback onCreateBudget;
  final VoidCallback? onDismiss;

  /// The chip when [HomeAiInsight.conversationId] is `null`: carries the
  /// seeded question/message text for the brand-new thread (bugfix item 7).
  final ValueChanged<String> onStartConversation;

  /// The chip when [HomeAiInsight.conversationId] is set: carries that exact
  /// id, reopening the conversation this insight already started instead of
  /// whatever thread is most recently active in general.
  final ValueChanged<String> onContinueConversation;

  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final theme = Theme.of(context);
    const money = MoneyFormatter();
    final isCreateBudget = insight.type == HomeAiInsightType.createBudget;
    final isSpendingUp = (insight.percentDelta ?? 0) >= 0;

    // Per-type chip label + seeded question — never the generic "iniciar
    // conversación" (bugfix item 7 follow-up): a specific, action-oriented
    // label invites the tap, and the seeded question must be an actual
    // question, not the button's own label (that was the bug: the old code
    // sent the chip's text as the message).
    final (startChipLabel, startQuestion) = switch (insight.type) {
      // Never read: `isCreateBudget` routes this type through `onCreateBudget`
      // below instead, with its own `homeAiChipBudgetHelp` copy. Kept here
      // only so the switch stays exhaustive.
      HomeAiInsightType.createBudget => (
          l10n.homeAiChipBudgetHelp,
          l10n.homeAiChipBudgetHelp,
        ),
      HomeAiInsightType.budgetProjectionRisk => (
          l10n.homeAiInsightProjectionChip,
          l10n.homeAiInsightProjectionQuestion,
        ),
      HomeAiInsightType.spendingVsAverage => isSpendingUp
          ? (
              l10n.homeAiInsightAverageUpChip,
              l10n.homeAiInsightAverageUpQuestion,
            )
          : (
              l10n.homeAiInsightAverageDownChip,
              l10n.homeAiInsightAverageDownQuestion,
            ),
    };

    final (icon, iconBg, iconColor, kicker, title, meta) =
        switch (insight.type) {
      HomeAiInsightType.createBudget => (
          LucideIcons.gauge,
          colors.tealSoft,
          colors.teal,
          l10n.homeAiInsightCreateBudgetKicker,
          l10n.homeAiInsightCreateBudgetTitle,
          l10n.homeAiInsightCreateBudgetMeta,
        ),
      HomeAiInsightType.budgetProjectionRisk => (
          LucideIcons.trendingUp,
          colors.amberSoft,
          colors.amber,
          l10n.homeAiInsightProjectionKicker,
          l10n.homeAiInsightProjectionTitle,
          l10n.homeAiInsightProjectionMeta(
            money.formatSymbol(
              insight.overageMinor ?? 0,
              currencyCode: insight.currency ?? 'COP',
            ),
          ),
        ),
      HomeAiInsightType.spendingVsAverage => (
          LucideIcons.trendingUp,
          colors.skySoft,
          colors.sky,
          l10n.homeAiInsightAverageKicker,
          (insight.percentDelta ?? 0) >= 0
              ? l10n.homeAiInsightAverageTitleUp(
                  (insight.percentDelta ?? 0).abs())
              : l10n.homeAiInsightAverageTitleDown(
                  (insight.percentDelta ?? 0).abs()),
          l10n.homeAiInsightAverageMeta,
        ),
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        InkWell(
          onTap: () => onAskQuestion(null),
          borderRadius: BorderRadius.circular(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 42,
                height: 42,
                alignment: Alignment.center,
                decoration:
                    BoxDecoration(color: iconBg, shape: BoxShape.circle),
                child: Icon(icon, size: 20, color: iconColor),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            kicker,
                            maxLines: 2,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: colors.textSecondary,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        if (insight.hasQueue)
                          Text(
                            l10n.homeAiInsightQueueCounter(
                              insight.queuePosition,
                              insight.queueLength,
                            ),
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: colors.textSecondary,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                      ],
                    ),
                    Text(
                      title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      meta,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colors.textSecondary,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: AiQuestionChip(
                label: isCreateBudget
                    ? l10n.homeAiChipBudgetHelp
                    : (insight.conversationId != null
                        ? l10n.homeAiInsightContinueChip
                        : startChipLabel),
                isDirectNav: isCreateBudget,
                onTap: isCreateBudget
                    ? onCreateBudget
                    : (insight.conversationId != null
                        ? () => onContinueConversation(insight.conversationId!)
                        : () => onStartConversation(startQuestion)),
              ),
            ),
            if (!isCreateBudget && onDismiss != null) ...[
              const SizedBox(width: 8),
              TextButton(
                onPressed: onDismiss,
                child: Text(l10n.homeAiInsightDismiss),
              ),
            ],
          ],
        ),
      ],
    );
  }
}
