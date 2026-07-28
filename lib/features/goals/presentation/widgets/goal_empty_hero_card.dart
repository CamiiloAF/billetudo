import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';

/// HU-13's selling empty-state hero (`qzBkN`'s `g6bBz0` Hero Card): a
/// `$primary-deep` → `$primary` diagonal gradient card with a translucent
/// medallion (`sparkles`) and the headline/sub copy in `$on-primary`.
///
/// The `.md`'s "Nunca el Empty State genérico" is literal here — this is a
/// bespoke widget, not `core/widgets/empty_state.dart`'s `EmptyState`, which
/// this screen deliberately does not use.
class GoalEmptyHeroCard extends StatelessWidget {
  const GoalEmptyHeroCard({
    required this.headline,
    required this.subtitle,
    super.key,
  });

  final String headline;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(22, 24, 22, 26),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [colors.primaryDeep, colors.primary],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 52,
            height: 52,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: colors.trackOverlay,
              borderRadius: BorderRadius.circular(26),
            ),
            child: Icon(LucideIcons.sparkles, size: 26, color: colors.onPrimary),
          ),
          const SizedBox(height: 12),
          Text(
            headline,
            style: theme.textTheme.headlineSmall?.copyWith(
              color: colors.onPrimary,
              fontSize: 24,
              fontWeight: FontWeight.w800,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            subtitle,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colors.onPrimary,
              fontSize: 14,
              fontWeight: FontWeight.w500,
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }
}
