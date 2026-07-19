import 'package:flutter/material.dart';

import '../../../../../core/theme/app_colors.dart';
import '../scheduled_category_icon_wrap.dart';

/// The `Sheet Icon Header` (`XPjIZ`): the category icon tile plus a
/// left-aligned name/sub pair, used by the sheets that act on one template
/// (Posponer) so the user always sees which payment they are moving.
class ScheduledSheetIconHeader extends StatelessWidget {
  const ScheduledSheetIconHeader({
    required this.title,
    required this.subtitle,
    required this.isTransfer,
    this.categoryIcon,
    this.categoryColor,
    super.key,
  });

  /// Already localized / already the template's display name.
  final String title;
  final String subtitle;
  final bool isTransfer;
  final String? categoryIcon;
  final String? categoryColor;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final theme = Theme.of(context);
    return Row(
      children: [
        ScheduledCategoryIconWrap(
          isTransfer: isTransfer,
          categoryIcon: categoryIcon,
          categoryColor: categoryColor,
          cornerRadius: 14,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: theme.textTheme.bodySmall?.copyWith(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: colors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
