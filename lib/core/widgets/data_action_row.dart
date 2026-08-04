import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../theme/app_colors.dart';
import '../theme/app_theme.dart';

/// The `Data Action Row` component (`CUUXW`): icon wrap + title + wrapping
/// description + an optional chip, on a `$surface` card with a chevron.
///
/// Used for the data-level actions of the sync/backup family ("Guardar una
/// copia"). The icon pair is passed in because it carries meaning: the local
/// file is `$teal`, never `$primary` — in this product violet means *the
/// cloud*, and tinting the local copy violet would blur exactly the
/// distinction these screens exist to keep.
class DataActionRow extends StatelessWidget {
  const DataActionRow({
    required this.icon,
    required this.iconColor,
    required this.iconBackground,
    required this.title,
    required this.description,
    required this.onTap,
    this.chipLabel,
    this.chipIcon,
    super.key,
  });

  final IconData icon;
  final Color iconColor;
  final Color iconBackground;

  /// Already localized.
  final String title;

  /// Already localized.
  final String description;

  /// Already localized. `null` hides the chip — the attention states turn it
  /// off, because there the row is the answer to a risk, not a feature label.
  final String? chipLabel;
  final IconData? chipIcon;

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final theme = Theme.of(context);
    final radius = BorderRadius.circular(AppTheme.radiusMedium);

    return Material(
      color: colors.surface,
      borderRadius: radius,
      child: InkWell(
        onTap: onTap,
        borderRadius: radius,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: radius,
            border: Border.all(color: colors.border),
          ),
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: iconBackground,
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 20, color: iconColor),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      description,
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        height: 1.4,
                        color: colors.textSecondary,
                      ),
                    ),
                    if (chipLabel case final chipLabel?) ...[
                      const SizedBox(height: 6),
                      DataActionChip(
                        label: chipLabel,
                        icon: chipIcon ?? LucideIcons.rotateCcw,
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Icon(LucideIcons.chevronRight, color: colors.textSecondary),
            ],
          ),
        ),
      ),
    );
  }
}

/// The chip inside a [DataActionRow] (`r3GFe`): 11/700 label on `$muted`.
class DataActionChip extends StatelessWidget {
  const DataActionChip({required this.label, required this.icon, super.key});

  /// Already localized.
  final String label;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: colors.muted,
        borderRadius: BorderRadius.circular(9),
      ),
      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 9),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: colors.textPrimary),
          const SizedBox(width: 5),
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: colors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}
