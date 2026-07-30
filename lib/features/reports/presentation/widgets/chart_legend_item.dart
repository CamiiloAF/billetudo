import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

/// The `Chart Legend Item` component (`DyQfQ`, `reusable:true`): a 10x10
/// color dot + label.
///
/// **Contract: color = the series it keys.** Never reuse this as a plain
/// section label with an arbitrary color — see
/// `design-system/billetudo/pages/graficas.md`, which deliberately keeps the
/// Resumen hero's figures off this component for exactly that reason.
class ChartLegendItem extends StatelessWidget {
  const ChartLegendItem({required this.color, required this.label, super.key});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final theme = Theme.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: colors.textSecondary,
          ),
        ),
      ],
    );
  }
}
