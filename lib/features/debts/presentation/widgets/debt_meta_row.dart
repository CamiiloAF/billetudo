import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

/// One line of the detail meta card (`bGC5u`/`rdxqA`/`Z4CoCi`): a
/// `$text-secondary` icon and a `$text-primary` value, with an optional badge
/// trailing (the "estimado" chip on the growth line).
class DebtMetaRow extends StatelessWidget {
  const DebtMetaRow({
    required this.icon,
    required this.text,
    this.trailing,
    super.key,
  });

  final IconData icon;
  final String text;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final trailing = this.trailing;
    return Row(
      children: [
        Icon(icon, size: 17, color: colors.textSecondary),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: colors.textPrimary,
                ),
          ),
        ),
        if (trailing != null) ...[const SizedBox(width: 8), trailing],
      ],
    );
  }
}
