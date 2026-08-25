import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

/// One "N filas se omitieron porque..." line inside `ImportSkippedSheet`
/// (`XRBVa`/`Aa1ek`): an icon, a color that matches the reason's severity,
/// and the localized count text.
class SkippedReasonRow extends StatelessWidget {
  const SkippedReasonRow({
    required this.icon,
    required this.color,
    required this.text,
    super.key,
  });

  final IconData icon;
  final Color color;
  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              height: 1.4,
              color: context.colors.textSecondary,
            ),
          ),
        ),
      ],
    );
  }
}
