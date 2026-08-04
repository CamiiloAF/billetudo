import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/theme/app_colors.dart';

/// The "+ Nueva" chip (`r1Oh6`, "Add Chip"), always last in
/// `GoalQuickAmountRow`: opens the minimal "Nuevo aporte rápido" sheet.
/// Neutral `$surface` fill with a `$border` stroke, `plus` icon and label in
/// `$primary-on-soft-strong` — an inviting affordance, not a disabled-looking
/// `$muted` one.
class GoalAddQuickAmountChip extends StatelessWidget {
  const GoalAddQuickAmountChip(
      {required this.label, required this.onTap, super.key});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final theme = Theme.of(context);

    return Material(
      color: colors.surface,
      borderRadius: BorderRadius.circular(18),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Container(
          height: 36,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: colors.border),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(LucideIcons.plus,
                  size: 14, color: colors.primaryOnSoftStrong),
              const SizedBox(width: 6),
              Text(
                label,
                style: theme.textTheme.labelMedium?.copyWith(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: colors.primaryOnSoftStrong,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
