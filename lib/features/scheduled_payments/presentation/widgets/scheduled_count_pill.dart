import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

/// "Activos · N" / "Terminados · N": a rounded pill counter.
class ScheduledCountPill extends StatelessWidget {
  const ScheduledCountPill({
    required this.label,
    required this.emphasized,
    super.key,
  });

  final String label;

  /// True for "Activos" (`$primarySoft`), false for "Terminados" (neutral
  /// `$muted`).
  final bool emphasized;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: emphasized ? colors.primarySoft : colors.muted,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: emphasized
                  ? colors.primaryOnSoftStrong
                  : colors.textSecondary,
              fontWeight: FontWeight.w700,
            ),
      ),
    );
  }
}
