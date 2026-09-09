import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';

/// One row of the "Avisos" section: icon, label, subtitle and a switch.
///
/// Same card shape as `ShowHelpOnEntryField` (`billetudo.pen` has no frame
/// for this section yet), so the block reads as part of Ajustes instead of a
/// new shape invented here.
class NotificationKindField extends StatelessWidget {
  const NotificationKindField({
    required this.icon,
    required this.label,
    required this.sublabel,
    required this.enabled,
    required this.onChanged,
    super.key,
  });

  final IconData icon;
  final String label;
  final String sublabel;
  final bool enabled;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final theme = Theme.of(context);

    return Material(
      color: colors.surface,
      borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: colors.primarySoft,
                borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
              ),
              child: Icon(icon, size: 20, color: colors.primaryOnSoft),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: theme.textTheme.titleSmall
                        ?.copyWith(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    sublabel,
                    style: theme.textTheme.bodySmall
                        ?.copyWith(color: colors.textSecondary),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Switch(value: enabled, onChanged: onChanged),
          ],
        ),
      ),
    );
  }
}
