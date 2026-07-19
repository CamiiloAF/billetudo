import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

/// A label/value row used by the confirmation sheet for read-only fields
/// (category, note) and for the editable date row (`editable: true` just
/// tints the value, the tap handling lives with the caller).
class ScheduledPaymentReadOnlyRow extends StatelessWidget {
  const ScheduledPaymentReadOnlyRow({
    required this.label,
    required this.value,
    this.editable = false,
    super.key,
  });

  final String label;
  final String value;
  final bool editable;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(color: colors.textSecondary),
          ),
          const Spacer(),
          Text(
            value,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: editable ? colors.primary : colors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}
