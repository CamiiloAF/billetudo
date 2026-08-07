import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';

/// The `Resumen Card` component (`Ii2Hs`): a bordered card holding a list of
/// label-value rows (e.g. "Importadas" / "120"), used in the import summary
/// (`Aa1ek`/`XRBVa`, HU-06 closing step). Rows can be separated by a thin
/// [SummaryStatsDivider] to group related stats (e.g. row counts vs. what
/// was created).
class SummaryStatsCard extends StatelessWidget {
  const SummaryStatsCard({required this.children, super.key});

  /// A mix of [SummaryStatsRow] and [SummaryStatsDivider].
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        border: Border.all(color: colors.border),
      ),
      child: Column(
        children: [
          for (var i = 0; i < children.length; i++) ...[
            if (i > 0) const SizedBox(height: 10),
            children[i],
          ],
        ],
      ),
    );
  }
}

/// A single label-value row inside a [SummaryStatsCard].
class SummaryStatsRow extends StatelessWidget {
  const SummaryStatsRow({required this.label, required this.value, super.key});

  /// Already localized.
  final String label;

  final String value;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final theme = Theme.of(context);

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: colors.textSecondary,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          value,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: colors.textPrimary,
          ),
        ),
      ],
    );
  }
}

/// A 1px divider (`oCVel`) between groups of [SummaryStatsRow].
class SummaryStatsDivider extends StatelessWidget {
  const SummaryStatsDivider({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(height: 1, color: context.colors.border);
  }
}
