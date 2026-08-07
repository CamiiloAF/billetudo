import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

/// The `Stat Chip` component (`U62qV`): a compact card with a bold value and
/// a small label below it, used in the import preview header and the copy
/// summary.
///
/// Sizes to its parent (`fill_container` in every `billetudo.pen` usage of
/// this component, e.g. `ScJz3`'s 4-up stats row) rather than a fixed width:
/// no explicit width of its own, so it fills a tight-constrained parent
/// (wrap each instance in `Expanded` when laying several out in a `Row`) and
/// still shrinks to its content inside a loose one (e.g. `Wrap`).
class StatChip extends StatelessWidget {
  const StatChip({required this.value, required this.label, super.key});

  final String value;

  /// Already localized.
  final String label;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colors.border),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            value,
            textAlign: TextAlign.center,
            style: theme.textTheme.titleLarge?.copyWith(
              fontSize: 20,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.labelSmall?.copyWith(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: colors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
