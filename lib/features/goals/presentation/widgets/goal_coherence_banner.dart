import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/l10n/gen/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../domain/entities/goal_with_progress.dart';
import '../utils/goal_format.dart';

/// HU-12's coherence signal (`RcCXl` Goal Coherence Row): a neutral `info`
/// row above the list, never blocking, never `triangle-alert`/`$expense`.
/// Tapping it navigates to the goals filtered by [GoalCoherenceSignal.accountId]
/// (`qFX42`).
class GoalCoherenceBanner extends StatelessWidget {
  const GoalCoherenceBanner({
    required this.signal,
    this.onTap,
    super.key,
  });

  final GoalCoherenceSignal signal;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);

    return Material(
      color: colors.skySoft,
      borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              Icon(LucideIcons.info, size: 18, color: colors.sky),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.goalCoherenceMessage(
                        GoalFormat.amount(
                          signal.overshootMinor,
                          signal.currency,
                        ),
                      ),
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: colors.textPrimary,
                        height: 1.35,
                      ),
                    ),
                    if (onTap != null) ...[
                      const SizedBox(height: 3),
                      Text(
                        l10n.goalCoherenceLink,
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: colors.primaryOnSoftStrong,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (onTap != null) ...[
                const SizedBox(width: 8),
                Icon(
                  LucideIcons.chevronRight,
                  size: 16,
                  color: colors.textSecondary,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
