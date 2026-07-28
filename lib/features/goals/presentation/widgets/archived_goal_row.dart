import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/l10n/gen/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/goal_with_progress.dart';
import '../cubit/archived_goals_cubit.dart';
import '../utils/goal_format.dart';
import '../utils/goal_icon_appearance.dart';
import 'goal_progress_ring.dart';
import 'sheets/confirm_archive_goal_sheet.dart';

/// A single archived goal row (HU-09, `G8lQvl` Archived Goal Row): a mini
/// progress ring, saved/target amounts, the linked account and archive date,
/// and a one-tap "Desarchivar" footer that restores it to the main list. A
/// completed goal wears the `$mint` treatment (card border/background, ring
/// fully filled) and a "Cumplida" badge instead of a percentage.
class ArchivedGoalRow extends StatelessWidget {
  const ArchivedGoalRow({
    required this.entry,
    required this.onTap,
    this.accountName,
    super.key,
  });

  final GoalWithProgress entry;

  /// The linked account's name, when the goal has one. `null` renders the
  /// meta line without an account prefix.
  final String? accountName;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final goal = entry.goal;
    final completed = goal.isCompleted;
    final accentColor = completed ? colors.mint : colors.border;
    final archivedAt = goal.archivedAt;

    return Material(
      color: completed ? colors.mintSoft : colors.surface,
      borderRadius: BorderRadius.circular(20),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: DecoratedBox(
          decoration: BoxDecoration(border: Border.all(color: accentColor)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    GoalProgressRing(
                      percent: entry.displayedPercent,
                      size: 48,
                      strokeWidth: 6,
                      completed: completed,
                      child: Icon(
                        GoalIconAppearance.iconFor(goal.icon),
                        size: 18,
                        color: completed ? colors.incomeText : colors.primaryOnSoft,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            goal.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: colors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  accountName == null
                                      ? l10n.goalRowArchivedOnNoAccount(
                                          archivedAt == null
                                              ? ''
                                              : GoalFormat.dateShort(
                                                  context, archivedAt),
                                        )
                                      : l10n.goalRowArchivedOn(
                                          accountName!,
                                          archivedAt == null
                                              ? ''
                                              : GoalFormat.dateShort(
                                                  context, archivedAt),
                                        ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                    color: colors.textSecondary,
                                  ),
                                ),
                              ),
                              Row(
                                children: [
                                  if (completed) ...[
                                    Icon(
                                      LucideIcons.partyPopper,
                                      size: 13,
                                      color: colors.incomeText,
                                    ),
                                    const SizedBox(width: 5),
                                  ],
                                  Text(
                                    completed
                                        ? l10n.goalRowCompletedBadge
                                        : '${entry.displayedPercent}%',
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      fontSize: 12,
                                      fontWeight: completed
                                          ? FontWeight.w800
                                          : FontWeight.w600,
                                      color: completed
                                          ? colors.incomeText
                                          : colors.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 6),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          GoalFormat.amount(entry.savedMinor, goal.currency),
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: colors.textPrimary,
                          ),
                        ),
                        if (!completed) ...[
                          const SizedBox(height: 2),
                          Text(
                            l10n.goalRowTargetOf(
                              GoalFormat.amount(goal.targetMinor, goal.currency),
                            ),
                            style: theme.textTheme.bodySmall?.copyWith(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: colors.textSecondary,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              InkWell(
                onTap: () => unawaited(_unarchive(context, goal.id)),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 13, horizontal: 14),
                  decoration: BoxDecoration(
                    border: Border(top: BorderSide(color: colors.border)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Icon(
                        LucideIcons.archiveRestore,
                        size: 18,
                        color: colors.primaryOnSoftStrong,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        l10n.goalRowUnarchive,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: colors.primaryOnSoftStrong,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _unarchive(BuildContext context, String goalId) async {
    final confirmed = await ConfirmArchiveGoalSheet.show(
      context,
      archiving: false,
    );
    if ((confirmed ?? false) && context.mounted) {
      await context.read<ArchivedGoalsCubit>().unarchive(goalId);
    }
  }
}
