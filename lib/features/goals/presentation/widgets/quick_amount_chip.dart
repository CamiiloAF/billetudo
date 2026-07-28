import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

/// A single tappable chip in `GoalQuickAmountRow` (a fixed quick amount, or
/// the "Otro" fallback, which alone carries a leading [icon] — a `pencil` in
/// `QBTVl`'s `MozMo`).
class QuickAmountChip extends StatelessWidget {
  const QuickAmountChip({
    required this.label,
    required this.onTap,
    this.icon,
    super.key,
  });

  final String label;
  final VoidCallback onTap;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final theme = Theme.of(context);
    final textStyle = theme.textTheme.labelLarge?.copyWith(
      fontSize: 14,
      fontWeight: FontWeight.w700,
      color: colors.primaryOnSoftStrong,
    );
    return Material(
      color: colors.primarySoft,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 13, horizontal: 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (icon case final icon?) ...[
                Icon(icon, size: 15, color: colors.primaryOnSoftStrong),
                const SizedBox(width: 6),
              ],
              Flexible(
                child: Text(
                  label,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: textStyle,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
