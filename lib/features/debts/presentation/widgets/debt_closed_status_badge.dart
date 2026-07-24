import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/theme/app_colors.dart';

/// The closed-tab status badge (`tHLtM` closed treatment, extension HU-07):
/// replaces the open card's "Cuota ·"/"Vence …" badge once a debt is closed. A
/// `$muted` pill (same slot as the open badge, no `$primary-soft` tint) with a
/// `$text-secondary` icon and label — `check` + "Pagada · <fecha>" when the
/// debt reached 0 before closing, `flag` + "Cerrada · <fecha>" when it was
/// closed with a balance still pending.
class DebtClosedStatusBadge extends StatelessWidget {
  const DebtClosedStatusBadge({
    required this.label,
    required this.settled,
    super.key,
  });

  /// Already localized ("Pagada · 12 mar" / "Cerrada · 2 feb").
  final String label;

  /// Whether the debt reached 0 before it was closed.
  final bool settled;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        color: colors.muted,
        borderRadius: BorderRadius.circular(8),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            settled ? LucideIcons.check : LucideIcons.flag,
            size: 12,
            color: colors.textSecondary,
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
                color: colors.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
