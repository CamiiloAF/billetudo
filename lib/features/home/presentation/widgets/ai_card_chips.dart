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
    required this.budgetChipIsDirectNav,
    required this.onAskQuestion,
    required this.onCreateBudget,
    super.key,
  });

  /// `HomeState.budgetChipIsDirectNav` — which arrow the last chip shows.
  final bool budgetChipIsDirectNav;

  final ValueChanged<String?> onAskQuestion;
  final VoidCallback onCreateBudget;

  /// `AiQuestionChip`'s own vertical padding (14 top + 14 bottom) plus two
  /// lines of its `bodySmall` label — see the call site's comment for why
  /// every chip is forced to this height instead of sizing to its own
  /// content.
  static const double _chipHeight = 64;

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
              Icon(LucideIcons.chevronRight,
                  size: 18, color: colors.primaryOnSoft),
            ],
          ),
        ),
        const SizedBox(height: 12),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              // Fixed, not `IntrinsicHeight`: `AiQuestionChip` measures its
              // own label with a `LayoutBuilder`, and `LayoutBuilder` cannot
              // answer an intrinsic-height query (Flutter throws at layout
              // time — confirmed live). `_chipHeight` reserves room for the
              // label's full 2 lines (`AiQuestionChip.maxLines`) plus its
              // vertical padding, so every chip renders at the same height
              // whether its own label needs one line or two.
              SizedBox(
                height: _chipHeight,
                child: AiQuestionChip(
                  label: l10n.homeAiChipMonthProgress,
                  onTap: () => onAskQuestion(l10n.homeAiChipMonthProgress),
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                height: _chipHeight,
                child: AiQuestionChip(
                  label: l10n.homeAiChipGoalsSaved,
                  onTap: () => onAskQuestion(l10n.homeAiChipGoalsSaved),
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                height: _chipHeight,
                child: AiQuestionChip(
                  label: l10n.homeAiChipBiggestSpend,
                  onTap: () => onAskQuestion(l10n.homeAiChipBiggestSpend),
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                height: _chipHeight,
                child: AiQuestionChip(
                  label: l10n.homeAiChipBudgetHelp,
                  isDirectNav: budgetChipIsDirectNav,
                  onTap: onCreateBudget,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
