import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

/// A single tappable chip in `GoalQuickAmountRow` (a fixed quick amount, or
/// the "Otro" fallback).
class QuickAmountChip extends StatelessWidget {
  const QuickAmountChip({required this.label, required this.onTap, super.key});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final theme = Theme.of(context);
    return Material(
      color: colors.primarySoft,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Text(
            label,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.labelLarge?.copyWith(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: colors.primaryOnSoftStrong,
            ),
          ),
        ),
      ),
    );
  }
}
