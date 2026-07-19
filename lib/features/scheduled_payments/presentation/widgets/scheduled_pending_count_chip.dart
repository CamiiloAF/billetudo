import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

/// The "×N" pill of a pending occurrence row (`QhuIP`): several occurrences
/// of the same template accumulated while the app was closed collapse into a
/// single row carrying this count. Neutral tone on purpose — it is a count,
/// not an alert — and it is the only surface where that number appears.
class ScheduledPendingCountChip extends StatelessWidget {
  const ScheduledPendingCountChip({required this.count, super.key});

  final int count;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
      decoration: BoxDecoration(
        color: colors.muted,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        '×$count',
        style: theme.textTheme.labelSmall?.copyWith(
          fontSize: 11,
          color: colors.textSecondary,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
