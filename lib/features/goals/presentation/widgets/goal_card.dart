import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/l10n/gen/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../domain/entities/goal_with_progress.dart';
import '../utils/goal_format.dart';
import '../utils/goal_icon_appearance.dart';
import 'goal_progress_ring.dart';

/// One row of the goals list (`dRg7r` Goal Card/Ring): mini-arco + ícono +
/// nombre (1 línea) + "Te faltan $X" dominante + meta line + chevron.
///
/// A completed goal switches to the compact "capítulo cerrado" treatment
/// (`ollx8`): a check medallion in `$income-text` and past-tense copy — the
/// big celebration lives in the 100% full-screen page, never repeated here.
class GoalCard extends StatelessWidget {
  const GoalCard({required this.entry, this.onTap, super.key});

  final GoalWithProgress entry;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final goal = entry.goal;
    final completed = goal.isCompleted;

    return Material(
      color: colors.surface,
      borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
            border: Border.all(color: colors.border),
          ),
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
          child: Row(
            children: [
              if (completed)
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: colors.mintSoft,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(LucideIcons.check, color: colors.incomeText),
                )
              else
                GoalProgressRing(
                  percent: entry.displayedPercent,
                  size: 44,
                  strokeWidth: 5,
                  child: Icon(
                    GoalIconAppearance.iconFor(goal.icon),
                    size: 18,
                    color: colors.primaryOnSoft,
                  ),
                ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      goal.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: colors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      completed
                          ? l10n.goalCardCompleted(
                              GoalFormat.amount(entry.savedMinor, goal.currency),
                            )
                          : l10n.goalCardRemaining(
                              GoalFormat.amount(
                                entry.remainingMinor,
                                goal.currency,
                              ),
                            ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: completed
                            ? colors.incomeText
                            : colors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      completed
                          ? l10n.goalCardChapterClosed
                          : l10n.goalCardMeta(entry.displayedPercent),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: colors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(LucideIcons.chevronRight, size: 18, color: colors.textSecondary),
            ],
          ),
        ),
      ),
    );
  }
}
