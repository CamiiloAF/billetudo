import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/l10n/gen/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import 'coming_soon_badge.dart';

/// A single row of the "Más" hub: icon + label, optionally flagged as
/// "Próximamente".
class MoreRow extends StatelessWidget {
  const MoreRow({
    required this.icon,
    required this.label,
    required this.onTap,
    this.comingSoon = false,
    super.key,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool comingSoon;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: colors.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: colors.muted,
                    borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                  ),
                  child: Icon(icon, size: 20, color: colors.textSecondary),
                ),
                const SizedBox(width: 12),
                Expanded(
                  // Row labels in `Mas — Final` reuse `Appearance Field`'s
                  // `Label` (`IwyuZ`): 600, not the baseline 500.
                  child: Text(
                    label,
                    style: theme.textTheme.titleSmall
                        ?.copyWith(fontWeight: FontWeight.w600),
                  ),
                ),
                if (comingSoon) ...[
                  ComingSoonBadge(label: l10n.comingSoonBadge),
                  const SizedBox(width: 8),
                ],
                Icon(LucideIcons.chevronRight, color: colors.textSecondary),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
