import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// The head of a picker sheet (`m3jomu/wvCSu`, `XsnnD/MDEn4`): a 17/700 title
/// and a wrapping 12/500 hint, both left-aligned, 4pt apart.
///
/// Distinct from `SheetActionsHead`, whose subtitle is a short single-line
/// label under a menu title; here the hint is a real sentence that wraps.
class SheetHead extends StatelessWidget {
  const SheetHead({required this.title, this.hint, super.key});

  /// Already localized.
  final String title;

  /// Already localized. `null` renders the title alone.
  final String? hint;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: theme.textTheme.titleMedium?.copyWith(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: colors.textPrimary,
          ),
        ),
        if (hint case final hint?) ...[
          const SizedBox(height: 4),
          Text(
            hint,
            style: theme.textTheme.bodySmall?.copyWith(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: colors.textSecondary,
            ),
          ),
        ],
      ],
    );
  }
}
