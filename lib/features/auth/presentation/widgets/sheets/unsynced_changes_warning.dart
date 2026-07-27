import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../../core/theme/app_colors.dart';

/// The `Unsynced Warning` block of "Cerrar sesión" (HU-06): what would be
/// lost by wiping this phone while the upload queue still has work.
///
/// Only rendered with the opt-in on **and** a count above zero; it sits
/// between the opt-in row and the buttons, never floating above the header.
///
/// The count is grouped into one total and never itemised by entity: listing
/// types ("3 movimientos, 2 presupuestos…") grows without bound right where
/// the text has to be read at a glance, before an irreversible action.
///
/// Contrast note: `textSecondary` on `amberSoft` is 4.77:1 in dark against a
/// 4.5 threshold — the tightest pair on this screen. Do not lighten or shrink
/// the body.
class UnsyncedChangesWarning extends StatelessWidget {
  const UnsyncedChangesWarning({
    required this.title,
    required this.body,
    super.key,
  });

  /// Already localized. Fixed — it does not vary with the count.
  final String title;

  /// Already localized, count included (ICU plural over the whole sentence).
  final String body;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colors.amberSoft,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(LucideIcons.cloudOff, size: 20, color: colors.amber),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    height: 1.3,
                    color: colors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  body,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    height: 1.35,
                    color: colors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
