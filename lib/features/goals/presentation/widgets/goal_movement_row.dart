import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/l10n/gen/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/goal_contribution.dart';
import '../utils/goal_format.dart';

/// One row of the goal's movement history (`wXkOU` Goal Movement Row):
/// direction icon-wrap, "Aporte"/"Retiro" + date/note, and the signed amount.
class GoalMovementRow extends StatelessWidget {
  const GoalMovementRow({
    required this.movement,
    required this.currency,
    this.onTap,
    super.key,
  });

  final GoalContribution movement;
  final String currency;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final isWithdrawal = movement.direction == GoalMovementDirection.withdrawal;
    final note = movement.note;
    final meta = note != null && note.isNotEmpty
        ? '${GoalFormat.dateShort(context, movement.date)} · $note'
        : GoalFormat.dateShort(context, movement.date);

    final row = Padding(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: isWithdrawal ? colors.muted : colors.primarySoft,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              isWithdrawal ? LucideIcons.arrowUpRight : LucideIcons.arrowDownLeft,
              size: 20,
              color: isWithdrawal ? colors.textSecondary : colors.primaryOnSoft,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isWithdrawal ? l10n.goalMovementWithdrawal : l10n.goalMovementContribution,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: colors.textPrimary,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  meta,
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
          const SizedBox(width: 12),
          Text(
            GoalFormat.signedAmount(movement, currency),
            style: theme.textTheme.bodyLarge?.copyWith(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: isWithdrawal ? colors.textSecondary : colors.textPrimary,
            ),
          ),
        ],
      ),
    );

    if (onTap == null) {
      return row;
    }
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(onTap: onTap, borderRadius: BorderRadius.circular(14), child: row),
    );
  }
}
