import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/theme/app_colors.dart';

/// The "Cuota · <fecha>" badge on the debt card's meta row (`tHLtM`): a
/// `calendar-clock` glyph and a label on a `$primary-soft` pill, both in
/// `$primary-on-soft-strong`. Shown when the debt has a linked cuota (HU-03).
class DebtInstallmentBadge extends StatelessWidget {
  const DebtInstallmentBadge({required this.label, super.key});

  final String label;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        color: colors.primarySoft,
        borderRadius: BorderRadius.circular(8),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            LucideIcons.calendarClock,
            size: 12,
            color: colors.primaryOnSoftStrong,
          ),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.labelSmall?.copyWith(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: colors.primaryOnSoftStrong,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
