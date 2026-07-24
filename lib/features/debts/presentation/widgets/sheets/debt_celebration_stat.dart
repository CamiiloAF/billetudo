import 'package:flutter/material.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_theme.dart';

/// One of the two stat tiles ("Total pagado/cobrado" / "Duración") shown by
/// the felicitación sheet (`DebtCelebrationSheet`).
class DebtCelebrationStat extends StatelessWidget {
  const DebtCelebrationStat({
    required this.value,
    required this.label,
    super.key,
  });

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        color: colors.primarySoft,
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            value,
            textAlign: TextAlign.center,
            style: theme.textTheme.titleMedium?.copyWith(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: colors.primaryOnSoftStrong,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodySmall?.copyWith(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: colors.primaryOnSoftStrong,
            ),
          ),
        ],
      ),
    );
  }
}
