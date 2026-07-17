import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/theme/app_colors.dart';

/// A `Tag Chip` as used on the transaction form. Two variants:
///
/// - assigned tag (`nM9ea`): a `primary-soft` pill, no border, with the tag
///   name and a removable `x`;
/// - the neutral "add" affordance (`Tag - Nueva`): a `muted` pill, no border,
///   with a leading `plus` and its label, both in `$text-secondary`.
class TransactionFormTagChip extends StatelessWidget {
  const TransactionFormTagChip({
    required this.label,
    required this.onTap,
    this.icon,
    this.removable = true,
    this.neutral = false,
    super.key,
  });

  final String label;
  final IconData? icon;

  /// When true the trailing icon is an `x` (remove); the whole chip is the tap
  /// target that removes it.
  final bool removable;

  /// When true the chip reads as the neutral gray "add" affordance instead of
  /// an assigned tag.
  final bool neutral;

  final VoidCallback onTap;

  static const double _radius = 18;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final theme = Theme.of(context);
    final fill = neutral ? colors.muted : colors.primarySoft;
    final foreground =
        neutral ? colors.textSecondary : colors.primaryOnSoftStrong;
    return Material(
      color: fill,
      borderRadius: BorderRadius.circular(_radius),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(_radius),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 14, color: foreground),
                const SizedBox(width: 6),
              ],
              Text(
                label,
                style: theme.textTheme.labelMedium?.copyWith(
                  color: foreground,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
              if (removable) ...[
                const SizedBox(width: 6),
                Icon(LucideIcons.x, size: 12, color: foreground),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
