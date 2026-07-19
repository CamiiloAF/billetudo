import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/theme/app_colors.dart';

/// A `Tag Chip`, shared by Transacciones and Pagos Programados. Two variants:
///
/// - assigned tag (`nM9ea`): a `primary-soft` pill, no border, with the tag
///   name and a removable `x`;
/// - the neutral "add" affordance (`rlnXj`, "Add Chip"): `$surface` fill,
///   1px `$border` stroke, with a leading `plus`/its label in
///   `$primary-on-soft-strong` — not `$muted`/`$text-secondary`, which reads
///   as disabled rather than an inviting affordance.
///
/// The tap target is padded to the 44pt minimum regardless of the chip's
/// visual (compact) size.
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

  /// When true the chip reads as the neutral "add" affordance instead of an
  /// assigned tag.
  final bool neutral;

  final VoidCallback onTap;

  static const double _radius = 18;
  static const double _minTapTarget = 44;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final theme = Theme.of(context);
    final fill = neutral ? colors.surface : colors.primarySoft;
    final foreground = colors.primaryOnSoftStrong;
    return IntrinsicWidth(
      child: Material(
        color: fill,
        borderRadius: BorderRadius.circular(_radius),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(_radius),
          child: Container(
            decoration: neutral
                ? BoxDecoration(
                    borderRadius: BorderRadius.circular(_radius),
                    border: Border.all(color: colors.border),
                  )
                : null,
            constraints: const BoxConstraints(minHeight: _minTapTarget),
            alignment: Alignment.center,
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
      ),
    );
  }
}
