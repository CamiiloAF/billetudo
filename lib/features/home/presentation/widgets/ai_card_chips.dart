import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/l10n/gen/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import 'ai_orb.dart';
import 'ai_question_chip.dart';

/// The "con chips" variant of `AiCard` (`MrROq`): Orb + generic copy + a
/// horizontal row of 4 [AiQuestionChip]s, the 4th always "Ayúdame a
/// presupuestar". The default variant of the card — shown regardless of chat
/// access.
class AiCardChips extends StatelessWidget {
  const AiCardChips({
    required this.onAskQuestion,
    required this.onCreateBudget,
    super.key,
  });

  final ValueChanged<String?> onAskQuestion;
  final VoidCallback onCreateBudget;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        InkWell(
          onTap: () => onAskQuestion(null),
          borderRadius: BorderRadius.circular(12),
          child: Row(
            children: [
              const AiOrb(),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      l10n.homeAiCardTitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      l10n.homeAiCardSubtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colors.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(LucideIcons.chevronRight, size: 18, color: colors.primaryOnSoft),
            ],
          ),
        ),
        const SizedBox(height: 12),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              AiQuestionChip(
                label: l10n.homeAiChipMonthProgress,
                onTap: () => onAskQuestion(l10n.homeAiChipMonthProgress),
              ),
              const SizedBox(width: 8),
              AiQuestionChip(
                label: l10n.homeAiChipGoalsSaved,
                onTap: () => onAskQuestion(l10n.homeAiChipGoalsSaved),
              ),
              const SizedBox(width: 8),
              AiQuestionChip(
                label: l10n.homeAiChipBiggestSpend,
                onTap: () => onAskQuestion(l10n.homeAiChipBiggestSpend),
              ),
              const SizedBox(width: 8),
              AiQuestionChip(
                label: l10n.homeAiChipBudgetHelp,
                isDirectNav: true,
                onTap: onCreateBudget,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
