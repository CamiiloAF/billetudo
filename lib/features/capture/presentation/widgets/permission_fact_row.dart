import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

/// `Permission Fact Row` (`OVVPQ`, `reusable:true`): a `$primary-soft` icon
/// tile, a 14/700 title and a 13/500 line of plain-language detail.
///
/// **Not interactive** — it explains, it does not navigate — so it carries no
/// chevron and no 44x44 tap target, exactly as the component says.
class PermissionFactRow extends StatelessWidget {
  const PermissionFactRow({
    required this.icon,
    required this.title,
    required this.description,
    super.key,
  });

  final IconData icon;

  /// Already localized.
  final String title;

  /// Already localized.
  final String description;

  @override
  Widget build(BuildContext context) {
    final AppColors colors = context.colors;
    final ThemeData theme = Theme.of(context);
    return Row(
      children: <Widget>[
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: colors.primarySoft,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, size: 18, color: colors.primaryOnSoft),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                title,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  height: 1.3,
                  color: colors.textPrimary,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                description,
                style: theme.textTheme.bodySmall?.copyWith(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  height: 1.4,
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
