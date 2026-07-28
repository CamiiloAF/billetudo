import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/l10n/gen/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../domain/entities/goal_with_progress.dart';
import '../cubit/archived_goals_cubit.dart';
import '../utils/goal_format.dart';
import '../utils/goal_icon_appearance.dart';
import 'sheets/confirm_archive_goal_sheet.dart';

/// A single archived goal row (HU-09): shows the icon, name, saved amount,
/// and a one-tap "Desarchivar" that restores it to the main list.
class ArchivedGoalRow extends StatelessWidget {
  const ArchivedGoalRow({required this.entry, required this.onTap, super.key});

  final GoalWithProgress entry;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final goal = entry.goal;

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
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: colors.muted,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  GoalIconAppearance.iconFor(goal.icon),
                  size: 18,
                  color: colors.textSecondary,
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
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: colors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      GoalFormat.amount(entry.savedMinor, goal.currency),
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: colors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              TextButton(
                onPressed: () => unawaited(_unarchive(context, goal.id)),
                child: Text(l10n.goalActionUnarchive),
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
