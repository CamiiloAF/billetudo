import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import 'period_selector.dart';

/// The `Chart Period Row` component (`c2u8DB`, `reusable:true`): the
/// `PeriodSelector` button plus a caption naming the resolved range.
/// **Never rendered on the Resumen tab** — decision D2,
/// `design-system/billetudo/pages/graficas.md`.
class ChartPeriodRow extends StatelessWidget {
  const ChartPeriodRow({
    required this.selectorLabel,
    required this.rangeCaption,
    required this.onTapSelector,
    super.key,
  });

  final String selectorLabel;
  final String rangeCaption;
  final VoidCallback onTapSelector;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final theme = Theme.of(context);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        PeriodSelector(label: selectorLabel, onTap: onTapSelector),
        const SizedBox(width: 10),
        Flexible(
          child: Text(
            rangeCaption,
            textAlign: TextAlign.end,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodySmall?.copyWith(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: colors.textSecondary,
            ),
          ),
        ),
      ],
    );
  }
}
