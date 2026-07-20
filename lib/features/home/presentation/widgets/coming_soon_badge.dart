import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

/// The small "Próximamente" pill shown on not-yet-built rows.
class ComingSoonBadge extends StatelessWidget {
  const ComingSoonBadge({required this.label, super.key});

  final String label;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final theme = Theme.of(context);
    return Container(
      // Matches Pencil's `Badge/Próximamente` (`yfvHv`): padding [4, 8], not
      // a wider 10px pill — the extra 4px total width quietly ate into the
      // title's budget in the "Más" hub rows that pair a title with this
      // badge (`Title Row`, `els07`).
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: colors.muted,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: theme.textTheme.labelSmall?.copyWith(
          color: colors.textSecondary,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
