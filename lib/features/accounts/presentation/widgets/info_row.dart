import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

/// The `Info Row` component: a label on the left, its value on the right.
class InfoRow extends StatelessWidget {
  const InfoRow({required this.label, required this.value, super.key});

  /// Both already localized: this widget renders, it does not translate.
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: Row(
        children: [
          Text(
            label,
            style: theme.textTheme.bodyMedium
                ?.copyWith(color: context.colors.textSecondary),
          ),
          const Spacer(),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodyMedium
                  ?.copyWith(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}
