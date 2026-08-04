import 'package:flutter/material.dart';

import '../../../../../core/theme/app_colors.dart';

/// One figure of `Hero Resumen` (`C2huAH`/`W2Sh0`): a label, a protagonist
/// count and a money sub-line, all neutral (`$text-primary`/`$text-
/// secondary`, no status color — nota `TvFBN`).
class ReportsDashboardHeroFigure extends StatelessWidget {
  const ReportsDashboardHeroFigure({
    required this.label,
    required this.value,
    required this.sub,
    super.key,
  });

  final String label;
  final String value;
  final String sub;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: colors.textSecondary,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          value,
          style: theme.textTheme.headlineSmall?.copyWith(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: colors.textPrimary,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          sub,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.bodySmall?.copyWith(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: colors.textSecondary,
          ),
        ),
      ],
    );
  }
}
